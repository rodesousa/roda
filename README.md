# Roda

> [Description coming soon]

## Prerequisites

- Elixir 1.18.4
- Docker and Docker Compose

## Getting Started

Clone the repository:

```bash
git clone <repository-url>
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

Install dependencies and start the Phoenix server:

```bash
make server
```

The application will be available at [`localhost:4000`](http://localhost:4000).
