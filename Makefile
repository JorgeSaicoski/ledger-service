# Makefile: database migration helpers

# Detect if podman or docker is available
CONTAINER_CMD := $(shell command -v podman 2> /dev/null || command -v docker 2> /dev/null)
COMPOSE_CMD := $(shell command -v podman-compose 2> /dev/null || command -v docker-compose 2> /dev/null)

.PHONY: start-db start-db-test stop-db stop-db-test migrate-db migrate-db-test

# Start production database (postgres on port 5432)
start-db:
	@echo "Starting production database using $(COMPOSE_CMD)..."
	@$(COMPOSE_CMD) up -d postgres
	@echo "Waiting for database to be ready..."
	@sleep 3

# Start test database (postgres-test on port 5433)
start-db-test:
	@echo "Starting test database using $(COMPOSE_CMD)..."
	@$(COMPOSE_CMD) up -d postgres-test
	@echo "Waiting for test database to be ready..."
	@sleep 3

# Stop production database
stop-db:
	@echo "Stopping production database..."
	@$(COMPOSE_CMD) stop postgres

# Stop test database
stop-db-test:
	@echo "Stopping test database..."
	@$(COMPOSE_CMD) stop postgres-test

# Stop all databases and remove volumes
stop-db-all:
	@echo "Stopping all databases and removing volumes..."
	@$(COMPOSE_CMD) down -v

# Run migrations against production database (creates db and runs migrations)
migrate-db: start-db
	@echo "Running migrations against production database..."
	@sleep 2
	@PGHOST=localhost \
	 PGPORT=5432 \
	 PGUSER=postgres \
	 PGPASSWORD=postgres \
	 PGDATABASE=ledger \
	 MIGRATIONS_DIR=migrations \
	 ./scripts/setup.sh
	@echo "✓ Production database migration complete!"

# Run migrations against test database (creates db and runs migrations)
migrate-db-test: start-db-test
	@echo "Running migrations against test database..."
	@sleep 2
	@PGHOST=localhost \
	 PGPORT=5433 \
	 PGUSER=test \
	 PGPASSWORD=test123 \
	 PGDATABASE=ledger_db_test \
	 MIGRATIONS_DIR=migrations \
	 ./scripts/setup.sh
	@echo "✓ Test database migration complete!"
