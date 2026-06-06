COMPOSE_PROJECT_NAME=postgrevector

.PHONY: up down verify clean help

help:
	@echo "Available targets:"
	@echo "  make up              - Build and start Docker Compose services"
	@echo "  make down            - Stop services and remove containers"
	@echo "  make verify          - Run the PostgreVector verification script"
	@echo "  make verify-windows - Run the verification script in PowerShell"
	@echo "  make clean           - Stop services, remove containers and volumes"

up:
	docker compose up --build --detach

down:
	docker compose down

verify:
	./test-postgrevector.sh

verify-windows:
	pwsh -NoProfile -ExecutionPolicy Bypass -File .\Test-PostgreVector.ps1

clean:
	docker compose down --volumes
