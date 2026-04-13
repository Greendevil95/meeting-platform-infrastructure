# Meeting Platform — инфраструктура

Docker Compose для локальной разработки: PostgreSQL, Redis, Kafka и вспомогательные UI.

## Требования

- [Docker](https://docs.docker.com/get-docker/) с плагином Compose (`docker compose version`)
- По желанию — [GNU Make](https://www.gnu.org/software/make/) для целей из `Makefile` (иначе те же команды можно выполнять вручную, см. ниже)

## Быстрый старт

```bash
cd meeting-platform-infrastructure
make up
```

Либо без Make:

```bash
docker compose -f docker-compose.yml up -d
```

Топики Kafka **не** создаются при `up`: их нужно завести отдельно (см. [Kafka: топики](#kafka-топики)).

## Сервисы и порты

| Сервис        | Назначение              | Порт на хосте |
|---------------|-------------------------|---------------|
| PostgreSQL    | База данных             | **5433** → 5432 |
| Redis         | Кэш / брокер сообщений  | **6379**      |
| Kafka         | Брокер (с хоста)        | **29092** (внутри сети Docker — `kafka:9092`) |
| Kafka UI      | Веб-интерфейс кластера  | **8090**      |
| Redis Insight | Веб-интерфейс Redis     | **8001**      |

Учётные данные PostgreSQL (как в `docker-compose.yml`):

- пользователь: `admin`
- пароль: `admin`
- БД по умолчанию: `postgres`

Скрипты из каталога `db-init/` выполняются при **первом** создании тома PostgreSQL (если том уже есть, изменения в SQL не применятся автоматически — нужен сброс тома или ручное применение миграций).

## Kafka: топики

Список топиков задаётся в массиве `TOPICS` в `scripts/kafka-init-topics.sh`. После правок скрипта образы пересобирать не нужно — снова выполните команду ниже.

Рекомендуемый способ:

```bash
make kafka-topics
```

Она поднимает Kafka при необходимости и запускает `docker run` в сети контейнера `meeting-kafka`.

Без Make (bash), из корня репозитория:

```bash
docker compose -f docker-compose.yml up -d kafka
NETWORK=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' meeting-kafka)
docker run --rm \
  -v "$(pwd)/scripts/kafka-init-topics.sh:/scripts/kafka-init-topics.sh:ro" \
  -e KAFKA_BOOTSTRAP_SERVERS=kafka:9092 \
  -e KAFKA_TOPIC_PARTITIONS=1 \
  -e KAFKA_TOPIC_REPLICATION_FACTOR=1 \
  --network "$NETWORK" \
  bitnamilegacy/kafka:latest \
  /bin/bash /scripts/kafka-init-topics.sh
```

В PowerShell переменную сети удобно задать так:  
`$NETWORK = docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' meeting-kafka`, затем тот же `docker run` с `--network $NETWORK` и путём к скрипту на вашей машине.

Приложения на **хосте** обычно подключаются к `localhost:29092`; сервисы **в той же Docker-сети** — к `kafka:9092`.

## Полезные команды (Makefile)

| Команда           | Описание |
|-------------------|----------|
| `make help`       | Краткая справка по целям |
| `make up`         | Поднять весь стек в фоне |
| `make down`       | Остановить и удалить контейнеры |
| `make ps`         | Статус сервисов |
| `make logs`       | Логи всех сервисов в режиме follow |
| `make kafka-up`   | Только Kafka |
| `make kafka-down` | Остановить Kafka |
| `make kafka-topics` | Поднять Kafka при необходимости и отдельным контейнером создать топики |
| `make kafka-logs` | Логи Kafka |

## Остановка

```bash
make down
```

или:

```bash
docker compose -f docker-compose.yml down
```

Чтобы удалить и данные PostgreSQL (тома), используйте `docker compose down -v` — **все данные БД будут удалены**.
