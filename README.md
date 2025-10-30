# Kong Study Environment

Docker Compose project for experimenting with [Kong](https://konghq.com/) as a reverse proxy and API gateway.

## What's Included

- **Kong Gateway** (`kong:3.5`) exposed on ports `8000/8443` (proxy) and `8001/8444` (Admin API).
- **PostgreSQL 14** backing database with persisted data in `kong_db_data`.
- **Automated migrations** container that initializes the database before Kong starts.
- **httpbin** upstream service to experiment with routing through Kong.

## Prerequisites

- Docker Engine 20.10+ and Docker Compose v2.5 or newer (for `depends_on` health conditions).
- Bash-compatible shell and `curl` (only needed for the helper script).

## Getting Started

1. Pull the container images (optional but avoids the initial download on first run):
   ```bash
   docker compose pull
   ```
2. Start the stack:
   ```bash
   docker compose up -d
   ```
3. Tail the Kong logs until you see `Kong started`:
   ```bash
   docker compose logs -f kong
   ```
4. Seed an example service and route that points to `httpbin`:
   ```bash
   ./scripts/seed-httpbin.sh
   ```
5. Call the upstream through Kong:
   ```bash
   curl http://localhost:8000/httpbin/get
   ```

### Useful URLs

- Kong Admin API: http://localhost:8001
- Kong Admin API (TLS): https://localhost:8444
- Kong proxy ingress: http://localhost:8000
- Kong status endpoint: http://localhost:8100/status
- Postgres (for tools such as psql): `postgres://kong:kongpassword@localhost:5432/kong`

## Customisation Tips

- Update `.env` to change Postgres credentials or the Compose project name.
- Modify `scripts/seed-httpbin.sh` or create new scripts to register additional services, routes, and plugins via the Admin API.
- Add plugin code or declarative config under a new directory (e.g. `kong/`) and mount it into the `kong` service using a volume if you want to experiment with custom logic.
- Prefer declarative workflows? See [Declarative Config](#declarative-config) for instructions on importing `config/kong.yml`.
- Want a DB-less setup instead? Use the separate compose file described in [DB-less Example](#db-less-example).

## Tear Down

Stop the stack and remove containers:
```bash
docker compose down
```

Remove the persisted Postgres volume as well (this deletes all Kong state):
```bash
docker compose down -v
```

### Using Make Targets

For convenience, common actions are available via the `Makefile`:

- `make pull` – fetch all container images ahead of time.
- `make up` / `make down` – start or stop the stack.
- `make logs` – follow Kong logs.
- `make seed` – register the `httpbin` service and route (respects `ADMIN_URL`).
- `make call` – send a sample request through the proxy (`/httpbin/get`).
- `make status` – query Kong's status endpoint.
- `make down-reset` – tear everything down and remove persisted data.
- `make config-import` – import `config/kong.yml` into the Postgres-backed Kong database.
- `make up-db-less` / `make down-db-less` – start or stop the declarative (DB-less) stack defined in `docker-compose.db-less.yml`.
- `make db-less-logs` / `make call-db-less` – follow logs or call the proxy of the DB-less stack.

## Declarative Config

Kong runs in **database mode** in this setup, which means it reads configuration from Postgres. Declarative YAML is typically used in **DB-less mode** (where `KONG_DATABASE=off`), so you generally choose one approach or the other.

However, you can still use a YAML file to bootstrap or replace the database contents:

1. Review or edit `config/kong.yml`. The example declares the `httpbin` service, a `/httpbin` route, a rate-limiting plugin, and a demo consumer with an API key.
2. Ensure the stack is up (`make up`) and migrations are complete.
3. Import the YAML into Postgres (this wipes existing Kong entities and replaces them with those found in the file):
   ```bash
   make config-import
   ```
4. Kong nodes poll the database and will pick up the new configuration automatically; check it with:
   ```bash
   curl -H "apikey: demo-api-key" http://localhost:8000/httpbin/get
   ```

Want pure declarative/DB-less mode instead? Set `KONG_DATABASE=off`, mount the YAML directly into the `kong` container, and skip the Postgres service entirely.

## DB-less Example

To keep things simple when experimenting with declarative config, there's an isolated compose file (`docker-compose.db-less.yml`) that runs Kong in DB-less mode alongside the same `httpbin` upstream:

1. Start the stack:
   ```bash
   make up-db-less
   ```
2. Watch Kong logs until it reports `Kong started`:
   ```bash
   make db-less-logs
   ```
3. Call the proxy using the API key seeded in `config/kong.yml`:
   ```bash
   curl -H "apikey: demo-api-key" http://localhost:8000/httpbin/get
   ```
4. Tear it down when finished:
   ```bash
   make down-db-less
   ```

Edit `config/kong.yml` and run `make up-db-less` (Compose will recreate the Kong container if the file changed) to iterate quickly without touching the database-backed example.
