import json
import os

import boto3
import psycopg2

DB_USER = "reader_user"
DB_PORT = 5432
CA_BUNDLE = os.path.join(os.path.dirname(__file__), "global-bundle.pem")
LIMIT = 20


def _mask_email(email):
    # test@example.com -> te**********.com
    if len(email) <= 6:
        return email[:1] + "*" * (len(email) - 1)
    return email[:2] + "*" * (len(email) - 6) + email[-4:]


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
    conn = None
    try:
        conn = _connect()
        with conn, conn.cursor() as cur:
            cur.execute(
                "SELECT id, email, message, created_at FROM tickets ORDER BY id DESC LIMIT %s",
                (LIMIT,),
            )
            tickets = [
                {"id": r[0], "email": _mask_email(r[1]), "message": r[2], "created_at": r[3].isoformat()}
                for r in cur.fetchall()
            ]
    except psycopg2.Error as exc:
        print(f"database error: {type(exc).__name__}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "could not read tickets"}),
        }
    finally:
        if conn is not None:
            conn.close()

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"tickets": tickets}),
    }
