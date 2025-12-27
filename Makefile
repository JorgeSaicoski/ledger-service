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
		$(CONTAINER_CMD) exec -i postgres psql -U postgres -d ledger_db -v ON_ERROR_STOP=1 < $$f; \
	done
	@echo "✓ Production database migration complete!"

# Run migrations against test database (localhost:5433)
migrate-db-test:
	@echo "Running migrations against test database..."
	@for f in migrations/*.sql; do \
		echo "Applying migration: $$f"; \
		$(CONTAINER_CMD) exec -i postgres psql -U test -d ledger_db_test -v ON_ERROR_STOP=1 < $$f; \
	done
	@echo "✓ Test database migration complete!"

# Optional: Start databases using docker/podman if needed

start-db:
	@echo "Starting production database using $(COMPOSE_CMD)..."
	@$(COMPOSE_CMD) up -d postgres

start-db-test:
	@echo "Starting test database using $(COMPOSE_CMD)..."
	@$(COMPOSE_CMD) up -d postgres-test

