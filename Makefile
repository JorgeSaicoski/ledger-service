# Makefile: database migration helpers

.PHONY: migrate-db migrate-db-test start-db start-db-test

# Detect container runtime
CONTAINER_CMD := $(shell command -v podman 2> /dev/null || command -v docker 2> /dev/null)
COMPOSE_CMD := $(shell command -v podman-compose 2> /dev/null || command -v docker-compose 2> /dev/null)

# Run migrations against production database (localhost:5432)
migrate-db:
	@echo "Running migrations against production database..."
	@for f in migrations/*.sql; do \
		echo "Applying migration: $$f"; \
		$(CONTAINER_CMD) exec -i ledger-postgres psql -U test -d ledger_db -v ON_ERROR_STOP=1 < $$f; \
	done
	@echo "✓ Production database migration complete!"

# Run migrations against test database (localhost:5432, different database)
migrate-db-test:
	@echo "Running migrations against test database..."
	@for f in migrations/*.sql; do \
		echo "Applying migration: $$f"; \
		$(CONTAINER_CMD) exec -i ledger-postgres psql -U test -d ledger_db_test -v ON_ERROR_STOP=1 < $$f; \
	done
	@echo "✓ Test database migration complete!"

# Start all services (database + application)
start:
	@echo "Starting all services using $(COMPOSE_CMD)..."
	@$(COMPOSE_CMD) up -d

# Start only the database
start-db:
	@echo "Starting database using $(COMPOSE_CMD)..."
	@$(COMPOSE_CMD) up -d postgres

# Stop all services
stop:
	@echo "Stopping all services..."
	@$(COMPOSE_CMD) down

# View logs
logs:
	@$(COMPOSE_CMD) logs -f

# Restart the application
restart-app:
	@echo "Restarting ledger-service..."
	@$(COMPOSE_CMD) restart ledger-service

