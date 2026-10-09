# n8n + PostgreSQL stack

Self-hosted n8n on Docker Compose with PostgreSQL as its database and task runners isolated in a sidecar.

## Architecture

```
            127.0.0.1:5678
                  │
            ┌─────▼─────┐   task broker :5679   ┌──────────────┐
            │    n8n    │◄──────────────────────│ task-runners │  Code node (JS / Python)
            └─────┬─────┘                       └──────────────┘
                  │ compose network only
            ┌─────▼──────────────────────┐
            │ PostgreSQL 17              │
            │  ├─ n8n  (n8n internal)    │
            │  └─ app  (workflow data)   │
            └────────────────────────────┘
```

- **Two databases, two roles.** `n8n` holds n8n's own state (workflows, credentials, executions). `app` holds business data that workflows read and write. Each database has its own non-superuser owner, so a workflow credential for `app` cannot touch n8n's internals.
- **Postgres is not published** — reachable only inside the compose network.
- **n8n listens on localhost only** — exposed through an HTTPS reverse proxy or an SSH tunnel.
- **Code runs out-of-process.** Code node executions go to the `n8nio/runners` sidecar (external mode), isolated from the main n8n process. Both images share one version tag (`N8N_VERSION`), so they can't drift apart.
- **Ordered startup.** n8n waits for the Postgres healthcheck (`pg_isready`) before starting.

## Setup

```bash
cp .env.example .env
openssl rand -hex 32   # run once per secret: passwords, N8N_ENCRYPTION_KEY, N8N_RUNNERS_AUTH_TOKEN
# fill in .env, set N8N_VERSION to the current stable tag
docker compose up -d
docker compose logs -f n8n
```

Open via SSH tunnel: `ssh -L 5678:localhost:5678 <server>` → http://localhost:5678

In workflows, the Postgres credential for business data is: host `postgres`, port `5432`, database `app`, user `app`.

## Notes

- `init/01-create-dbs.sh` runs **only on the first start with an empty volume**. To re-run it: `docker compose down -v` (deletes all data).
- **Back up `N8N_ENCRYPTION_KEY`.** Stored credentials are encrypted with it; without the key they cannot be recovered.
- Upgrading: change `N8N_VERSION` in `.env`, then `docker compose pull && docker compose up -d`.
