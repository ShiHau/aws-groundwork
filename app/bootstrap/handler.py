"""One-off RDS bootstrap, invoked by Terraform during apply.

Connects as the master user (password read from the RDS-managed Secrets
Manager secret) and applies rds_bootstrap.sql, which must be idempotent.
"""
import json
import logging
import os
import time
from pathlib import Path

import boto3
import psycopg2

logger = logging.getLogger(__name__)
logging.getLogger("botocore").setLevel(logging.WARNING)

SQL_PATH = Path(__file__).with_name("rds_bootstrap.sql")
CA_BUNDLE = os.path.join(os.path.dirname(__file__), "global-bundle.pem")


def get_master_password():
    secrets = boto3.client("secretsmanager")
    secret = secrets.get_secret_value(SecretId=os.environ["secret_arn"])
    return json.loads(secret["SecretString"])["password"]


def lambda_handler(event, context):
    # Failures are not caught here: the runtime logs uncaught exceptions as JSON (errorType,
    # errorMessage, stackTrace) and the failed invocation makes `terraform apply` fail loudly.
    started = time.perf_counter()
    logger.info("bootstrap starting", extra={"dbHost": os.environ["db_host"], "dbName": os.environ["db_name"]})
    conn = psycopg2.connect(
        host=os.environ["db_host"],
        dbname=os.environ["db_name"],
        user=os.environ["db_user"],
        password=get_master_password(),
        sslmode="verify-full",
        sslrootcert=CA_BUNDLE,
        connect_timeout=10,
    )
    try:
        with conn, conn.cursor() as cur:
            cur.execute(SQL_PATH.read_text())
    finally:
        conn.close()

    logger.info("bootstrap complete", extra={"durationMs": round((time.perf_counter() - started) * 1000)})
    return {"status": "ok"}
