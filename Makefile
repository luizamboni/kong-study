.PHONY: pull up logs seed call status down down-reset config-import up-db-less down-db-less call-db-less db-less-logs

DOCKER_COMPOSE ?= docker compose
ADMIN_URL ?= http://localhost:8001
PROXY_URL ?= http://localhost:8000
STATUS_URL ?= http://localhost:8100/status
CONFIG_FILE ?= $(CURDIR)/config/kong.yml
DB_LESS_COMPOSE ?= docker compose -f docker-compose.db-less.yml
DB_LESS_PROXY_URL ?= http://localhost:8000

pull:
	$(DOCKER_COMPOSE) pull

up:
	$(DOCKER_COMPOSE) up -d

logs:
	$(DOCKER_COMPOSE) logs -f kong

seed:
	ADMIN_URL=$(ADMIN_URL) ./scripts/seed-httpbin.sh

call:
	curl -i $(PROXY_URL)/httpbin/get

status:
	curl -i $(STATUS_URL)

down:
	$(DOCKER_COMPOSE) down

down-reset:
	$(DOCKER_COMPOSE) down -v

config-import:
	$(DOCKER_COMPOSE) run --rm --no-deps \
		-v $(CONFIG_FILE):/config/kong.yml:ro \
		--entrypoint kong kong \
		config db_import /config/kong.yml

up-db-less:
	$(DB_LESS_COMPOSE) up -d

down-db-less:
	$(DB_LESS_COMPOSE) down

db-less-logs:
	$(DB_LESS_COMPOSE) logs -f kong

call-db-less:
	curl -i $(DB_LESS_PROXY_URL)/httpbin/get
