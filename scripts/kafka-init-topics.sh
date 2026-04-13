#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP="${KAFKA_BOOTSTRAP_SERVERS:-kafka:9092}"
PARTITIONS="${KAFKA_TOPIC_PARTITIONS:-1}"
REPLICATION="${KAFKA_TOPIC_REPLICATION_FACTOR:-1}"
KAFKA_TOPICS_BIN="${KAFKA_TOPICS_BIN:-/opt/bitnami/kafka/bin/kafka-topics.sh}"

TOPICS=(
  "user-service.user-created"
  "user-service.user-updated"
  "user-service.user-deleted"
  "user-service.user-status-changed"
  "meeting-service.meeting-created"
  "meeting-service.meeting-updated"
  "meeting-service.meeting-cancelled"
  "meeting-service.meeting-participant-added"
  "meeting-service.meeting-participant-removed"
)

echo "Waiting for Kafka at ${BOOTSTRAP}..."
until "${KAFKA_TOPICS_BIN}" --bootstrap-server "${BOOTSTRAP}" --list >/dev/null 2>&1; do
  echo "Kafka is not ready yet..."
  sleep 2
done

echo "Kafka is ready. Creating topics..."

for topic in "${TOPICS[@]}"; do
  "${KAFKA_TOPICS_BIN}" --create --if-not-exists \
    --topic "${topic}" \
    --bootstrap-server "${BOOTSTRAP}" \
    --partitions "${PARTITIONS}" \
    --replication-factor "${REPLICATION}"
done

echo "All topics created successfully."
