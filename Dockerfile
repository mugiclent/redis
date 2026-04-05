FROM cgr.dev/chainguard/redis:latest

# Chainguard Redis is built on Wolfi — minimal OS, no shell, non-root by default.
# Typically ships with zero critical CVEs vs the official Alpine/Debian images.
# Redis plugins/modules would be added here if needed.
# Config is mounted via docker-compose — see config/redis.conf.
