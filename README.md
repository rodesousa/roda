# Roda

> [Description coming soon]

## Prerequisites

- Elixir 1.18.4
- Docker and Docker Compose

## Getting Started

Clone the repository:

```bash
git clone git@github.com:rodesousa/roda.git
cd roda
```

Set up environment variables:

```bash
cp env.sample .env
```

Set `CLOAK_KEY` in `.env` with `make gen_cloak`

Start the Docker services (PostgreSQL and MinIO):

```bash
make up
```

Run database migrations to create all schemas

```bash
make ecto_migration
```

Install dependencies and start the Phoenix server:

```bash
make server
```

The application will be available at [`localhost:4000`](http://localhost:4000).

## Technical Documentation

Detailed technical specifications and architecture documents:

- [Audio Recording System](./docs/architecture/audio_recording.md) - Real-time audio recording with chunk-based storage in MinIO
- [LLM Providers System](./docs/architecture/llm_providers.md) - Dynamic LLM configuration with encrypted API keys

## Production Deployment

For production deployment with Docker Compose:

- [Deployment Guide](./docs/DEPLOYMENT.md) - Complete production deployment guide with HTTPS, automated migrations, and monitoring
