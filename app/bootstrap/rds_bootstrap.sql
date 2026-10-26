-- Applied by the bootstrap Lambda as the RDS master user. Must stay idempotent.
CREATE TABLE IF NOT EXISTS tickets (
    id         SERIAL PRIMARY KEY,
    email      VARCHAR(255) NOT NULL,
    message    TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Grant lambda user connect to db and do insert
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'lambda_user') THEN
        CREATE USER lambda_user WITH LOGIN;
    END IF;
END
$$;

GRANT rds_iam TO lambda_user;
GRANT CONNECT ON DATABASE groundwork_rds_db TO lambda_user;

GRANT USAGE ON SCHEMA public TO lambda_user;
GRANT INSERT ON TABLE tickets TO lambda_user;
GRANT USAGE ON SEQUENCE tickets_id_seq TO lambda_user;

-- Grant reader user connect to db and do select
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'reader_user') THEN
        CREATE USER reader_user WITH LOGIN;
    END IF;
END
$$;

GRANT rds_iam TO reader_user;
GRANT CONNECT ON DATABASE groundwork_rds_db TO reader_user;
GRANT USAGE ON SCHEMA public TO reader_user;
GRANT SELECT ON TABLE tickets TO reader_user;
