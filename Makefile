up:
	@docker compose up -d

down:
	@docker compose down -v

env:
	@cp env.sample .env

server:
	@iex -S mix phx.server

ecto_migration:
	@mix ecto.migrate

gen_secret:
	@mix phx.gen.secret 32
