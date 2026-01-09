.PHONY: help up down restart build logs test test-unit test-integration clean permissions update stop ps

# Default target
help:
	@echo "Available targets:"
	@echo "  make up          - Start all services"
	@echo "  make down        - Stop and remove all services"
	@echo "  make stop        - Stop all services without removing"
	@echo "  make restart     - Restart all services"
	@echo "  make build       - Build the application"
	@echo "  make rebuild     - Rebuild and start services"
	@echo "  make logs        - View service logs"
	@echo "  make test        - Run all tests"
	@echo "  make test-unit   - Run unit tests"
	@echo "  make test-integration - Run integration tests"
	@echo "  make clean       - Clean up containers, volumes, and build artifacts"
	@echo "  make permissions - Set correct permissions for scripts"
	@echo "  make update      - Update dependencies"
	@echo "  make ps          - List running containers"

# Start services
up:
	podman-compose up -d
	@echo "Services started. Waiting for database..."
	@sleep 5
	@echo "Services are ready!"

# Stop services
down:
	podman-compose down

# Stop services without removing
stop:
	podman-compose stop

# Restart services
restart: down up

# Build the application
build:
	podman-compose build

# Rebuild and start
rebuild: down build up

# View logs
logs:
	podman-compose logs -f

# Run all tests
test:
	@chmod +x tests/run_tests.sh
	@./tests/run_tests.sh

# Run unit tests
test-unit:
	go test -v ./internal/...

# Run integration tests
test-integration:
	@chmod +x tests/test_*.sh
	@./tests/test_create_transaction.sh
	@./tests/test_get_transaction.sh
	@./tests/test_list_transactions.sh

# Clean up
clean:
	podman-compose down -v
	rm -f ledger-service
	go clean

# Set permissions
permissions:
	chmod +x scripts/setup.sh
	chmod +x init-db.sh
	chmod +x tests/*.sh
	@echo "Permissions set for all scripts"

# Update dependencies
update:
	go get -u ./...
	go mod tidy
	podman-compose pull
	@echo "Dependencies updated"

# List running containers
ps:
	podman-compose ps
