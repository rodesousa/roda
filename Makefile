up:
	@docker-compose up -d

env:
	@cp env.sample .env

server:
	@iex -S mix phx.server
