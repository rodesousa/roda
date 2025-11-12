# ===================================
# Build Stage
# ===================================
FROM elixir:1.19.1-otp-28-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Set build ENV
ENV MIX_ENV=prod

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy config
COPY config config

# Copy application source (needed for phoenix-colocated hooks)
COPY lib lib

# Copy assets
COPY assets assets
COPY priv priv

# Install npm dependencies
RUN cd assets && npm ci && cd ..

# Compile application (needed for phoenix-colocated to generate hooks)
RUN mix compile

# Build and deploy assets
RUN mix assets.deploy

# Build release
RUN mix release

# ===================================
# Runtime Stage
# ===================================

FROM debian:bookworm-slim AS app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libstdc++6 \
    openssl \
    libncurses6 \
    ca-certificates \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Set UTF-8 locale
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Create app user
RUN groupadd -g 1000 app && \
    useradd -u 1000 -g app -s /bin/bash -m app

# Set working directory
WORKDIR /app

# Copy release from builder
COPY --from=builder --chown=app:app /app/_build/prod/rel/roda ./

# Set user
USER app

# Set environment
ENV HOME=/app
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD nc -z localhost 4000 || exit 1

# Start command
CMD ["/app/bin/roda", "start"]
