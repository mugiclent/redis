# katisha — redis

Redis 7 cache and session store for the Katisha platform, running in Docker on
the `katisha-net` bridge network. Every configuration change is made in this
repo; GitHub Actions handles the rest automatically.

---

## How it works

```
push to main
    └─ GitHub Actions
           └─ SSH into server
                  ├─ git clone (first time) or git pull
                  ├─ write .env from secrets
                  ├─ patch requirepass in config/redis.conf from secret
                  ├─ docker compose up -d --build
                  │      ├─ rebuilds image if Dockerfile changed
                  │      ├─ recreates container if config changed
                  │      └─ leaves the redis_data volume untouched
                  └─ waits for healthy status
```

The volume is **never touched** by the pipeline. Only a manual
`docker compose down -v` would remove it.

---

## Repository layout

```
redis/
├── Dockerfile                   # base image; add modules here if needed
├── docker-compose.yml           # container, volume, network wiring
├── config/
│   └── redis.conf               # all Redis configuration
├── .env.example                 # template — copy to .env for local dev
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD pipeline
└── README.md
```

---

## Making changes

### Tuning Redis

Edit [config/redis.conf](config/redis.conf), commit, and push. The container
is recreated automatically on the next deploy; the data volume is not affected.

Key values to adjust:

| Setting | Notes |
|---|---|
| `maxmemory` | Cap Redis RAM usage — set below total server RAM |
| `maxmemory-policy` | `allkeys-lru` for caching, `volatile-lru` for session store |
| `appendfsync` | `everysec` (default) balances durability vs performance |

### Password

The password is never stored in the repo. The deploy pipeline injects it from
the `REDIS_PASSWORD` GitHub secret by patching `config/redis.conf` at deploy
time. To rotate the password: update the secret, push any change to trigger
a deploy.

### Adding a Redis module

1. Add the build step to [Dockerfile](Dockerfile)
2. Add the `loadmodule` directive to [config/redis.conf](config/redis.conf)
3. Commit and push

---

## GitHub Actions secrets

Set these under **Settings → Secrets and variables → Actions** in the repo.

| Secret | Description |
|---|---|
| `SERVER_HOST` | IP address or hostname of the production server |
| `SERVER_USER` | SSH username (must be in the `docker` group) |
| `SERVER_SSH_KEY` | Private SSH key |
| `REDIS_PASSWORD` | Redis auth password |

---

## One-time server setup

The `katisha-net` Docker network must exist on the server (created once,
shared with all Katisha services):

```bash
docker network create katisha-net
```

The pipeline handles cloning the repo and starting the container on the first push.

---

## Local development

```bash
cp .env.example .env
# edit .env with your local password
# also patch config/redis.conf manually for local use:
sed -i "s|requirepass REDIS_PASSWORD_PLACEHOLDER|requirepass your_local_password|" config/redis.conf
docker compose up -d --build
```

---

## Network & connectivity

The container is named `redis` and listens on port `6379` inside `katisha-net`.
Other services connect using:

```
redis://:password@redis:6379
```

No port is exposed to the host. Only containers on `katisha-net` can reach it.

---

## Timezone

The container runs in `Africa/Kigali` (UTC+2, Central Africa Time) via the
`TZ` environment variable.
