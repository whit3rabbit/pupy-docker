# Makefile for Pupy Docker
.PHONY: build up down logs shell clean generator help config config-edit config-show

# Default target
help:
	@echo "Pupy C2 Docker Management"
	@echo "========================"
	@echo "make build       - Build Docker image"
	@echo "make up          - Start Pupy server"
	@echo "make down        - Stop Pupy server"
	@echo "make logs        - View server logs"
	@echo "make shell       - Get shell in container"
	@echo "make generator   - Run pupygen interactively"
	@echo "make clean       - Clean up containers and volumes"
	@echo ""
	@echo "Configuration Commands:"
	@echo "make config      - Show configuration status"
	@echo "make config-edit - Edit configuration file"
	@echo "make config-show - Display current configuration"
	@echo ""
	@echo "Payload Generation:"
	@echo "make payload-win - Generate Windows x64 payload"
	@echo "make payload-lin - Generate Linux x64 payload"
	@echo "make payloads    - List all generated payloads"

build:
	docker-compose build

up:
	docker-compose up -d pupy-server
	@echo "Pupy server started. View logs with: make logs"

down:
	docker-compose down

logs:
	docker-compose logs -f pupy-server

shell:
	docker-compose run --rm pupy-server bash

generator:
	docker-compose run --rm pupy-generator pupygen -l

clean:
	docker-compose down -v
	rm -rf ./data/* ./output/*
	@echo "Cleaned up data and output directories"

# Configuration management
config:
	@echo "Configuration Status:"
	@echo "===================="
	@if [ -f "./config/pupy.conf" ]; then \
		echo "✓ Custom config exists: ./config/pupy.conf"; \
		echo "  Last modified: $(stat -c %y ./config/pupy.conf 2>/dev/null || stat -f %Sm ./config/pupy.conf)"; \
	else \
		echo "✗ No custom config found. Default will be used."; \
		echo "  Run 'make up' once to generate the default config."; \
	fi
	@echo ""
	@echo "Container config location: /home/pupy/.config/pupy/pupy.conf"

config-edit:
	@if [ -f "./config/pupy.conf" ]; then \
		${EDITOR:-nano} ./config/pupy.conf; \
	else \
		echo "Config file not found. Run 'make up' first to generate it."; \
	fi

config-show:
	@if [ -f "./config/pupy.conf" ]; then \
		cat ./config/pupy.conf | grep -E "^\[|^[^#].*="; \
	else \
		echo "Config file not found. Run 'make up' first to generate it."; \
	fi

# Payload generation shortcuts
payload-win:
	@mkdir -p ./output
	docker-compose run --rm pupy-generator pupygen -O windows -A x64 -o ./output/payload-win64.exe
	@echo "Payload saved to ./output/payload-win64.exe"

payload-lin:
	@mkdir -p ./output
	docker-compose run --rm pupy-generator pupygen -O linux -A x64 -o ./output/payload-linux64
	@echo "Payload saved to ./output/payload-linux64"

payloads:
	@echo "Generated Payloads:"
	@echo "==================="
	@if [ -d "./output" ] && [ "$(ls -A ./output 2>/dev/null)" ]; then \
		ls -la ./output/; \
	else \
		echo "No payloads found in ./output/"; \
	fi