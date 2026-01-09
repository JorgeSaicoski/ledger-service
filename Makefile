# Makefile: database migration helpers
.PHONY: migrate-db migrate-db-test start-db start-db-test
# Detect container runtime with full paths
CONTAINER_CMD := $(shell command -v /usr/bin/podman 2> /dev/null || command -v /usr/local/bin/podman 2> /dev/null || command -v podman 2> /dev/null || command -v /usr/bin/docker 2> /dev/null || command -v docker 2> /dev/null)
COMPOSE_CMD := $(shell command -v /usr/bin/podman-compose 2> /dev/null || command -v /usr/local/bin/podman-compose 2> /dev/null || command -v podman-compose 2> /dev/null || command -v /usr/bin/docker-compose 2> /dev/null || command -v docker-compose 2> /dev/null)
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
# Clean build cache and rebuild from scratch
clean:
@echo "Cleaning up build cache..."
@$(COMPOSE_CMD) down -v 2>/dev/null || true
@$(CONTAINER_CMD) system prune -f 2>/dev/null || true
@echo "✓ Clean complete!"
# Start all services (database + application) - rebuild without cache
start:
@echo "Starting all services using $(COMPOSE_CMD)..."
@$(COMPOSE_CMD) build --no-cache
@$(COMPOSE_CMD) up -d
# Alias for start
up: start
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
# Run tests
test:
@echo "Running Go tests..."
@go test -v -cover ./...
# Run tests with coverage report
test-coverage:
@echo "Running tests with coverage..."
@go test -v -coverprofile=coverage.out ./...
@go tool cover -html=coverage.out -o coverage.html
@echo "✓ Coverage report generated: coverage.html"
