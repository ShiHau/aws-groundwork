"""One-off RDS bootstrap, invoked by Terraform during apply.

Connects as the master user (password read from the RDS-managed Secrets
Manager secret) and applies rds_bootstrap.sql, which must be idempotent.
"""
import json
import os
from pathlib import Path

import boto3
import psycopg2

SQL_PATH = Path(__file__).with_name("rds_bootstrap.sql")


def get_master_password():
    secrets = boto3.client("secretsmanager")
    secret = secrets.get_secret_value(SecretId=os.environ["secret_arn"])
    return json.loads(secret["SecretString"])["password"]


def lambda_handler(event, context):
    conn = psycopg2.connect(
        host=os.environ["db_host"],
        dbname=os.environ["db_name"],
        user=os.environ["db_user"],
        password=get_master_password(),
        sslmode="require",
        connect_timeout=10,
    )
    try:
        with conn, conn.cursor() as cur:
            cur.execute(SQL_PATH.read_text())
    finally:
        conn.close()

    return {"status": "ok"}
