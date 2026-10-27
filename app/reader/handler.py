import json
import logging
import os
import time

import boto3
import psycopg2

# See app_lambda/main.py: the Lambda runtime renders these as JSON when log_format is JSON.
logger = logging.getLogger(__name__)
logging.getLogger("botocore").setLevel(logging.WARNING)

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


def _request_fields(event):
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


def lambda_handler(event, context):
    fields = _request_fields(event)
    started = time.perf_counter()
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
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "could not read tickets"}),
        }
    finally:
        if conn is not None:
            conn.close()

    logger.info(
        "tickets read",
        extra={
            **fields,
            "outcome": "read",
            "status": 200,
            "ticketCount": len(tickets),
            "dbDurationMs": round((time.perf_counter() - started) * 1000),
        },
    )
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"tickets": tickets}),
    }
