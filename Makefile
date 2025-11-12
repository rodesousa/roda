PG_NAME=postgres
PG_USER=postgres
PG_DB=roda_dev

up:
	@docker compose -f ./docker-compose-dev.yml up -d

down:
	@docker compose -f ./docker-compose-dev.yml  down

purge:
	@docker compose -f ./docker-compose-dev.yml  down -v

server:
	@iex -S mix phx.server

ecto_migration:
	@mix ecto.migrate

gen_secret:
	@mix phx.gen.secret 32

# Usage: make extract_chunk CHUNK_ID=uuid-here
CHUNK_ID ?= chunk
extract_chunk:
	@echo "Extracting chunk: $(CHUNK_ID).webm"
	@docker exec roda-minio-1 /usr/bin/mc cp myminio/roda/audio-chunks/$(CHUNK_ID).webm /tmp/$(CHUNK_ID).webm
	@docker cp roda-minio-1:/tmp/$(CHUNK_ID).webm ./$(CHUNK_ID).webm
	@echo "Chunk saved to: ./$(CHUNK_ID).webm"

ecto_rollback:
	@echo "mix ecto.rollback OR mix ecto.rollback --step 2 OR mix ecto.rollback -to ID_TIMESPAMP"

gettext:
	@mix gettext.extract --merge --no-fuzzy

gen_cloak:
	@openssl rand -base64 32

backup:
	@docker exec -it $(PG_NAME) bash -c "pg_dump -h localhost $(PG_DB) -U $(PG_USER) > backup.sql"
	@docker cp $(PG_NAME):/backup.sql backup-`date +'%Y-%m-%d'`.sql
