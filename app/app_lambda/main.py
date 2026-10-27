import json
import logging
import os
import time

import boto3
import psycopg2

# With the function's log format set to JSON, the Lambda runtime renders these records as JSON,
# adds requestId automatically, and merges any `extra={...}` keys in as top-level fields.
# The level is controlled by the function's application_log_level, so it is not set here.
logger = logging.getLogger(__name__)
# botocore logs credential discovery at INFO on every cold start; that is noise, not signal.
logging.getLogger("botocore").setLevel(logging.WARNING)

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


def _request_fields(event):
    # apiRequestId matches $context.requestId in the API Gateway access log, linking the two.
    request_context = event.get("requestContext") or {}
    return {"apiRequestId": request_context.get("requestId"), "route": event.get("routeKey")}


def _db_error_fields(exc):
    # Only the first line of the server message: DETAIL lines can echo row values (i.e. user data).
    message = str(exc).strip().splitlines()
    return {
        "dbErrorType": type(exc).__name__,
        "pgcode": exc.pgcode,
        "dbErrorMessage": message[0] if message else None,
    }


def _reject(fields, reason):
    logger.warning("request rejected", extra={**fields, "outcome": "rejected", "reason": reason, "status": 400})
    return _response(400, {"error": reason})


def lambda_handler(event, context):
    fields = _request_fields(event)

    body = _parse_body(event)
    if body is None:
        return _reject(fields, "body must be a JSON object")

    email = body.get("email")
    message = body.get("message")

    if not isinstance(email, str) or not isinstance(message, str) or not email.strip() or not message.strip():
        return _reject(fields, "email and message are required strings")
    if len(email) > MAX_EMAIL_LEN or len(message) > MAX_MESSAGE_LEN:
        return _reject(fields, "email or message too long")

    started = time.perf_counter()
    conn = None
    try:
        conn = _connect()
        with conn, conn.cursor() as cur:
            cur.execute(
                "INSERT INTO tickets (email, message) VALUES (%s, %s)",
                (email.strip(), message),
            )
    except psycopg2.Error as exc:
        logger.error(
            "database error",
            extra={
                **fields,
                **_db_error_fields(exc),
                "outcome": "error",
                "status": 500,
                "dbDurationMs": round((time.perf_counter() - started) * 1000),
            },
        )
        return _response(500, {"error": "could not save ticket"})
    finally:
        if conn is not None:
            conn.close()

    logger.info(
        "ticket created",
        extra={
            **fields,
            "outcome": "created",
            "status": 200,
            "messageLength": len(message),
            "dbDurationMs": round((time.perf_counter() - started) * 1000),
        },
    )
    return _response(200, {"message": "Ticket created successfully"})
