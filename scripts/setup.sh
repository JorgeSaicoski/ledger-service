#!/bin/sh

# Updated setup script: creates the database if needed and applies all SQL files
# from migrations/ (or $MIGRATIONS_DIR). Uses psql with ON_ERROR_STOP so failures
# abort the run. Designed for non-interactive use in CI and Makefile targets.

set -eu

: "${PGHOST:=localhost}"
: "${PGPORT:=5432}"
: "${PGUSER:=test}"
: "${PGPASSWORD:=}"
: "${PGDATABASE:=ledger_db}"
: "${MIGRATIONS_DIR:=migrations}"

export PGPASSWORD

echo "[setup.sh] Host=$PGHOST Port=$PGPORT User=$PGUSER Database=$PGDATABASE Migrations=$MIGRATIONS_DIR"

# Check that psql is available
if ! command -v psql >/dev/null 2>&1; then
  echo "psql not found in PATH. Install PostgreSQL client tools."
  exit 1
fi

# Create database if it doesn't exist
echo "[setup.sh] Ensuring database '$PGDATABASE' exists..."
DB_EXISTS=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -v dbname="$PGDATABASE" -tAc "SELECT 1 FROM pg_database WHERE datname = :'dbname'" || true)
if [ "${DB_EXISTS}" != "1" ]; then
  echo "[setup.sh] Creating database $PGDATABASE..."
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -v dbname="$PGDATABASE" -c 'CREATE DATABASE :"dbname";'
else
  echo "[setup.sh] Database $PGDATABASE already exists."
fi

# Apply migrations
if [ ! -d "$MIGRATIONS_DIR" ]; then
  echo "[setup.sh] Migrations directory '$MIGRATIONS_DIR' not found. Nothing to do."
  exit 0
fi

for f in "$MIGRATIONS_DIR"/*.sql; do
  [ -e "$f" ] || continue
  echo "[setup.sh] Applying migration: $f"
  psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f "$f"
done

echo "[setup.sh] All migrations applied."
