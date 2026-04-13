.PHONY: help up down ps logs kafka-up kafka-down kafka-topics kafka-logs

DOCKER_COMPOSE := docker compose -f docker-compose.yml

help:
	@echo "Meeting platform — Docker Compose"
	@echo ""
	@echo "  make up            — поднять весь стек в фоне"
	@echo "  make down          — остановить и удалить контейнеры"
	@echo "  make ps            — статус сервисов"
	@echo "  make logs          — логи всех сервисов (Ctrl+C — выход)"
	@echo ""
	@echo "Kafka:"
	@echo "  make kafka-up      — только Kafka"
	@echo "  make kafka-down    — остановить Kafka"
	@echo "  make kafka-topics  — отдельный контейнер: поднять Kafka при необходимости"
	@echo "                       и создать топики из scripts/kafka-init-topics.sh"
	@echo "  make kafka-logs    — логи Kafka"

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

ps:
	$(DOCKER_COMPOSE) ps

logs:
	$(DOCKER_COMPOSE) logs -f

kafka-up:
	$(DOCKER_COMPOSE) up -d kafka

kafka-down:
	$(DOCKER_COMPOSE) stop kafka

# Одноразовый контейнер (не сервис compose): та же Docker-сеть, что у meeting-kafka
KAFKA_TOPICS_IMAGE ?= bitnamilegacy/kafka:latest

kafka-topics:
	docker run --rm \
	  -v "$(CURDIR)/scripts/kafka-init-topics.sh:/scripts/kafka-init-topics.sh:ro" \
	  -e KAFKA_BOOTSTRAP_SERVERS=kafka:9092 \
	  -e KAFKA_TOPIC_PARTITIONS=1 \
	  -e KAFKA_TOPIC_REPLICATION_FACTOR=1 \
	  --network meeting-network \
	  $(KAFKA_TOPICS_IMAGE) \
	  /bin/bash /scripts/kafka-init-topics.sh

kafka-logs:
	$(DOCKER_COMPOSE) logs -f kafka
