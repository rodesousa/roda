# LLM Providers System - Technical Documentation

## Overview

Dynamic LLM provider configuration system ([instructor_ex](https://github.com/thmsmlr/instructor_ex)) with encrypted API keys storage ([cloak_ecto](https://github.com/danielberkompas/cloak_ecto)). Allows users to configure multiple LLM providers (OpenAI, Anthropic, Google, etc.) via admin interface without application restart.

**Key Features:**
- Dynamic provider configuration (no env vars, no restart)
- Encrypted API keys in database
- Multi-provider support
- Instructor integration for structured outputs
- User-friendly admin interface

## Security: API Key Encryption

### Why Encrypt API Keys?

API keys are **highly sensitive credentials**:
- Grant access to paid services
- Can incur significant costs if leaked
- May access private data/models
- Required by compliance standards (GDPR, SOC2)

### Key Management

**CLOAK_KEY Generation:**
```bash
# Option 1: OpenSSL
openssl rand -base64 32

# Option 2: Mix task
mix phx.gen.secret 32
```

**Storage:**
```bash
# .env (NOT committed to git)
CLOAK_KEY=3Jnb4X9cF8kN2pL7qR5sT6vY8zA1bC3dE4fG5hH6iJ7kK8lL9mM0nN1oO2pP3qQ=
```
