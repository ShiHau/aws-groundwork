import json
import os

import boto3
import psycopg2

DB_USER = "lambda_user"
DB_PORT = 5432
CA_BUNDLE = os.path.join(os.path.dirname(__file__), "global-bundle.pem")

MAX_EMAIL_LEN = 255
MAX_MESSAGE_LEN = 5000


def _response(status, payload):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload),
    }


def _parse_body(event):
    raw = event.get("body") or "{}"
    try:
        body = json.loads(raw)
    except (TypeError, ValueError):
        return None
    return body if isinstance(body, dict) else None


def _connect():
    host = os.environ["db_endpoint"]
    token = boto3.client("rds", region_name=os.environ["AWS_REGION"]).generate_db_auth_token(
        DBHostname=host, Port=DB_PORT, DBUsername=DB_USER
    )
    return psycopg2.connect(
        host=host,
        port=DB_PORT,
        dbname=os.environ["db_name"],
        user=DB_USER,
        password=token,
        sslmode="verify-full",
        sslrootcert=CA_BUNDLE,
        connect_timeout=5,
    )


def lambda_handler(event, context):
    body = _parse_body(event)
    if body is None:
        return _response(400, {"error": "body must be a JSON object"})

    email = body.get("email")
    message = body.get("message")

    if not isinstance(email, str) or not isinstance(message, str) or not email.strip() or not message.strip():
        return _response(400, {"error": "email and message are required strings"})
    if len(email) > MAX_EMAIL_LEN or len(message) > MAX_MESSAGE_LEN:
        return _response(400, {"error": "email or message too long"})

    conn = None
    try:
        conn = _connect()
        with conn, conn.cursor() as cur:
            cur.execute(
                "INSERT INTO tickets (email, message) VALUES (%s, %s)",
                (email.strip(), message),
            )
    except psycopg2.Error as exc:
        print(f"database error: {type(exc).__name__}")
        return _response(500, {"error": "could not save ticket"})
    finally:
        if conn is not None:
            conn.close()

    return _response(200, {"message": "Ticket created successfully"})
