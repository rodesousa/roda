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
make env
```

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

- [Audio Recording System](./docs/architecure/audio_recording.md) - Real-time audio recording with chunk-based storage in MinIO
