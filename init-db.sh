#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE ledger_db_test;
    GRANT ALL PRIVILEGES ON DATABASE ledger_db_test TO test;

EOSQL
