# Heroku Migration Plan

## Recommendation

Use Railway as the first staging target because it matches the existing
Dockerfile, offers usage-based billing with a $5/month Hobby minimum, managed
PostgreSQL, S3-compatible object storage, volumes/backups, custom-domain SSL,
and WebSocket support. These are platform capabilities, not a guaranteed
monthly saving; the real comparison requires the current Heroku dyno,
Postgres, Redis, and add-on usage.

- [Railway pricing](https://railway.com/pricing)
- [Railway PostgreSQL](https://docs.railway.com/databases/postgresql)
- [Railway data and storage](https://docs.railway.com/data-storage)
- [Railway volume backups](https://docs.railway.com/volumes/backups)
- [Railway public networking and SSL](https://docs.railway.com/networking/domains/working-with-domains)
- [Railway WebSockets](https://docs.railway.com/guides/sse-vs-websockets)

Render is the fallback when a more Rails-specific deployment workflow is more
valuable than usage-based pricing. Its Rails 8 guide covers PostgreSQL,
background workers, and Solid Queue; it also documents Action Cable support.
Render's filesystem is ephemeral by default, and attaching a persistent disk
disables zero-downtime deploys, so uploads should still move to object storage.

- [Render Rails 8 deployment](https://render.com/docs/deploy-rails-8)
- [Render service types](https://render.com/docs/service-types)
- [Render WebSockets](https://render.com/docs/websocket)
- [Render persistent disks](https://render.com/docs/disks)

Fly.io/Kamal remains a control-first option, but it carries more operational
responsibility for database, volume, and rollback management. It is not the
first target for an easier deployment.

- [Fly.io Rails](https://fly.io/docs/rails/)
- [Fly.io pricing and storage](https://fly.io/docs/about/pricing/)

## Current application map

| Area | Current state | Migration consequence |
| --- | --- | --- |
| Runtime | Rails 8, Puma, Dockerfile, Kamal config | Deploy the existing image first; avoid a framework rewrite. |
| Database | Production `pg`; `DATABASE_URL`; Solid Cache/Queue/Cable tables use PostgreSQL configuration | Provision PostgreSQL, restore data, then run all Rails migrations including `db/cache_migrate`, `db/queue_migrate`, and `db/cable_migrate`. |
| Jobs | Solid Queue; Kamal currently enables `SOLID_QUEUE_IN_PUMA=true` | Start with one service for parity; split a dedicated worker after cutover if load requires it. |
| Realtime | Action Cable with `solid_cable` at `/cable` | Use `wss://` through the public domain and verify reconnect behavior after deploys. |
| Uploads | Active Storage production service is local filesystem | Move to S3-compatible object storage before production cutover. Do not rely on an ephemeral service filesystem. |
| Email | SMTP is commented out; production host is `example.com` | Configure SMTP credentials, real host, default URL options, and delivery-error monitoring. |
| Secrets | `RAILS_MASTER_KEY` is the documented deployment secret | Store it and all provider credentials in the target secret manager; never commit them. |
| Assets | Docker precompiles assets; Puma reads `PORT` | Keep the Docker build, add provider health checks, and bind the public port through the provider. |
| Android push | Capacitor client is present; FCM config is absent; server sender is a logging placeholder | Treat push as a separate integration: Firebase project/config, sender implementation, token lifecycle, and device test. |

## Phases

### 1. Preflight and inventory

1. Record Heroku app, dyno, Postgres, add-on, storage, email, and monthly
   usage; capture configuration *names only*, never secret values.
2. Export a verified Heroku PostgreSQL backup and record its timestamp,
   database size, row counts, and restore procedure.
3. Identify where existing Active Storage files actually live. Heroku local
   dyno storage is not a durable source of truth.
4. Lower DNS TTL before the cutover and document current DNS records.
5. Confirm a real production hostname for mailer links and Action Cable.

### 2. Make the app provider-neutral

1. Add a production object-storage service and migrate Active Storage without
   changing attachment APIs in models or views.
2. Configure SMTP through environment variables and set the real host in
   `default_url_options`.
3. Add a health check that verifies application boot and database reachability;
   keep it free of authentication and external side effects.
4. Keep Solid Queue and Solid Cable on PostgreSQL for the first deployment;
   do not add Redis unless measurements or provider constraints require it.
5. Add deployment documentation/configuration only after staging proves the
   exact commands and environment names.

### 3. Build a staging target

Create a separate Railway project/environment with:

- Rails web service from the existing Dockerfile.
- Managed PostgreSQL connected through `DATABASE_URL`.
- `RAILS_MASTER_KEY`, `RAILS_ENV=production`, `RAILS_LOG_LEVEL`, `WEB_CONCURRENCY`,
  mailer settings, object-storage settings, and Action Cable host settings.
- A worker service only if the single-process Solid Queue arrangement is not
  sufficient.
- Object storage for uploads; no application volume for user files.
- Generated provider domain and HTTPS before testing WebSockets.

Run migrations in staging, restore a sanitized database snapshot, upload a
test attachment, send a test email, exercise chat/whiteboard connections, run
jobs, and verify Android's web endpoint against the staging hostname.

### 4. Data and file migration

1. Put the application in a short maintenance/read-only window.
2. Take a final PostgreSQL dump from Heroku and restore it into the target.
3. Run Rails migrations and verify schema versions for primary, cache, queue,
   and cable databases/tables.
4. Copy Active Storage blobs to object storage and verify blob counts and
   representative downloads.
5. Rotate only the target credentials needed for the new environment.
6. Run smoke checks for login, CRUD, exports, mail, jobs, chat, whiteboards,
   public forms, and logout/session expiry.

### 5. Cutover and rollback

1. Freeze writes, take the final backup, and record the migration ID.
2. Deploy the target with the final database and object-storage credentials.
3. Point DNS to the target and verify TLS, `/up`, login, Action Cable, mail,
   uploads, and background jobs.
4. Keep Heroku available but read-only during the observation window.
5. Roll back DNS and resume Heroku if any acceptance check fails; do not run
   divergent writes on both platforms.
6. After the agreed observation period, disable Heroku workers/add-ons and
   retain the final backup and logs according to the recovery policy.

## Decision gates

- Do not cut over until object storage, SMTP, database restore, Action Cable,
  and job execution are proven in staging.
- Do not claim a cost saving until the Heroku inventory and target usage
  estimate are compared over the same traffic and retention assumptions.
- Do not enable production Android push until Firebase credentials and a real
  device test are available.

## Open inputs

- Current Heroku monthly invoice and resource configuration.
- Production hostname/DNS provider.
- Email provider and sender domain.
- Object-storage provider and retention requirements.
- Acceptable maintenance window and rollback observation period.
- Firebase project configuration for Android push.
