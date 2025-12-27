#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE ledger_db_test;

    DO
    \$\$
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM   pg_catalog.pg_roles
            WHERE  rolname = 'test'
        ) THEN
            CREATE ROLE test LOGIN;
        END IF;
    END
    \$\$;
    GRANT ALL PRIVILEGES ON DATABASE ledger_db_test TO test;

EOSQL
