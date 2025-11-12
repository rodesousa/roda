# Deployment Guide - Roda Production

## Prerequisites

- Docker & Docker Compose installed
- Domain name pointing to your server
- Ports 80 and 443 open on your firewall

## Quick Start

### 1. Clone and setup environment

```bash
cd /home/rodesousa/git/roda
cp .env.example.prod .env.prod
```

### 2. Configure environment variables

Copy env.example.prod .env and set:

```bash
# Your domain
PHX_HOST=your-domain.com

# Generate secrets
SECRET_KEY_BASE=$(mix phx.gen.secret)
CLOAK_KEY=$(openssl rand -base64 32)

# Database passwords (change these!)
POSTGRES_PASSWORD=your_secure_postgres_password
MINIO_ROOT_PASSWORD=your_secure_minio_password
MEMGRAPH_PASSWORD=your_secure_memgraph_password

# Let's Encrypt email
ACME_EMAIL=your-email@example.com

# Update DATABASE_URL with your postgres password
DATABASE_URL=ecto://roda:your_secure_postgres_password@postgres:5432/roda_prod

# Bootstrap configuration (initial organization and admin user)
INITIAL_ORG_NAME=Your Organization
ADMIN_EMAIL=admin@your-domain.com
ADMIN_PASSWORD=your_secure_admin_password
```

### 3. Build and start services

```bash
# Start all services (including migrations)
docker-compose -f docker-compose-prod.yml --env-file .env.prod up -d
```

The `migrate` service will automatically run database migrations before the app starts.

### 4. Run seeds (first deployment only)

After the first deployment, you need to create the initial organization and admin user:

```bash
# Run seeds to create initial organization and admin user
docker-compose -f docker-compose-prod.yml --env-file .env.prod exec app /app/bin/roda eval "Roda.Release.seed"
```

This command is **idempotent** - you can run it multiple times safely. It will:
- Create the initial organization (if it doesn't exist)
- Create the admin user with the credentials from your `.env.prod` file
- Assign admin role and super admin privileges

Your application should now be accessible at `https://your-domain.com`

**Login with:**
- Email: The value from `ADMIN_EMAIL` in your `.env.prod`
- Password: The value from `ADMIN_PASSWORD` in your `.env.prod`

## Services

The stack includes:

- **Traefik**: Reverse proxy with automatic HTTPS (Let's Encrypt)
- **PostgreSQL**: Database with pgvector extension
- **Memgraph**: Graph database
- **MinIO**: Object storage
- **Phoenix App**: Your Roda application

## Traefik & HTTPS

Traefik automatically:
- Redirects HTTP (port 80) to HTTPS (port 443)
- Obtains and renews SSL certificates from Let's Encrypt
- Routes traffic to your Phoenix app

Certificates are stored in the `traefik-certificates` volume.

## Database Migrations

Migrations run automatically via the `migrate` service before the app starts. This ensures:
- Migrations complete before the app launches
- Safe deployments even with multiple app instances
- Clear failure if migrations fail

### Manual migration commands

```bash
# Run migrations manually
docker-compose -f docker-compose-prod.yml --env-file .env.prod run --rm migrate
```

## Seeds (Bootstrap Data)

Seeds are used to create the initial organization and admin user. They are **idempotent** and safe to run multiple times.

### Running seeds

```bash
# Run seeds (creates initial org and admin if they don't exist)
docker-compose -f docker-compose-prod.yml --env-file .env.prod exec app /app/bin/roda eval "Roda.Release.seed"
```

### What seeds do

The seed script (`priv/repo/seeds.exs`) will:
1. Check if an organization exists - if not, create one using `INITIAL_ORG_NAME`
2. Check if the admin user exists - if not, create one using `ADMIN_EMAIL` and `ADMIN_PASSWORD`
3. Create the membership linking the user to the organization
4. Grant super admin privileges to the user

**Important:** Make sure to set strong passwords in your `.env.prod` file for production!

## Backup

### PostgreSQL

```bash
docker exec postgres pg_dump -U roda roda_prod > backup_$(date +%Y%m%d).sql
```

### MinIO

```bash
docker exec minio mc mirror myminio/roda /backup/minio
```

### Memgraph

```bash
docker exec memgraph bash -c "echo 'DUMP DATABASE;' | mgconsole" > memgraph_backup_$(date +%Y%m%d).cypher
```

## Troubleshooting

### View logs

```bash
# All services
docker-compose -f docker-compose-prod.yml --env-file .env.prod logs -f

# Specific service
docker-compose -f docker-compose-prod.yml --env-file .env.prod logs -f app
docker-compose -f docker-compose-prod.yml --env-file .env.prod logs -f traefik
```
