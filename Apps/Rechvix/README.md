# rechvix on CasaOS / ZimaOS

This directory holds the app store manifest and assets that let rechvix
install as a one-click app on [CasaOS](https://casaos.io) and
[ZimaOS](https://zimaspace.com) (ZimaOS uses the identical `x-casaos`
compose schema). Structure verified against this project's sibling,
[nodedr-pos](https://github.com/Raktim94/nodedr-pos)'s real,
already-submitted CasaOS manifest.

| File | Purpose |
| --- | --- |
| `docker-compose.yml` | The app manifest itself — standard Compose plus a top-level `x-casaos:` block CasaOS reads to render the store listing and install form. |
| `icon.png` | 512×512 square app icon. |
| `thumbnail.png` | 720×450 store-listing banner. |
| `screenshot-1.png` … `screenshot-3.png` | Dashboard, and two other real screens from the running app. |

## Install it right now (before official app store approval)

CasaOS and ZimaOS can both install directly from a compose file URL —
you don't need to wait for this to land in the official app store:

1. In CasaOS/ZimaOS, go to **App Store → + (top right) → Install a customized app** (CasaOS) or the equivalent **Custom Install / Install via Compose** option in ZimaOS.
2. Paste this URL (or the raw file contents):

   ```
   https://raw.githubusercontent.com/Raktim94/rechvix/main/casaos/docker-compose.yml
   ```

3. Set `POSTGRES_PASSWORD`, `BILLING_APP_PASSWORD` (two different strong
   passwords), and `AEAD_ENCRYPTION_KEY` (`openssl rand -base64 32`) in the
   install form.
4. Install. CasaOS pulls the pre-built `ghcr.io/raktim94/rechvix-server`
   and `ghcr.io/raktim94/rechvix-worker` images — there is no build step,
   so it works even though CasaOS never touches this repo's source.
5. Open it from the CasaOS dashboard, or go straight to
   `http://<your-casaos-box>:8090`, then `/setup` to create your business
   (organisation, first branch/warehouse, and owner login).

Your data (the Postgres cluster — invoices, inventory, accounting,
everything) persists at `/DATA/AppData/rechvix/postgres` on the CasaOS
box, following the same convention CasaOS's own backup/restore UI expects
for every other app.

## Why one app image, not a separate frontend container

Unlike nodedr-pos (`backend` + `frontend`), rechvix ships its full web UI
(dashboard, sales, purchases, inventory, contacts, accounting, GST/tax,
reports, settings) served directly by `apps/server` — no separate frontend
container needed. The manifest declares `main: app` for that reason;
CasaOS uses this to know which container's port to open when you click the
app.

`migrate` is a one-shot container (`restart: "no"`) that runs database
migrations and exits; `app` and `worker` both wait on it via
`service_completed_successfully` before starting.

## Publishing new image versions

`docker-compose.yml` here pins exact image tags (CasaOS requires pinned,
not `:latest`, tags). To publish a new version:

1. Bump the version everywhere it's referenced — the `image:` tags for
   `migrate`, `app`, and `worker` in this file, and `version:` under
   `x-casaos:`.
2. Run the **Publish Docker images** workflow
   (`.github/workflows/docker-publish.yml`) via `workflow_dispatch` with
   that version, or just push to `main` with changes under
   `apps/server/`, `apps/worker/`, `internal/`, `migrations/`, or
   `deploy/docker/` — it also tags a build from the latest git tag
   automatically. It builds both images for `linux/amd64` **and**
   `linux/arm64` (a lot of CasaOS/ZimaOS boxes are ARM SBCs) and pushes
   them to GHCR.
3. Confirm both new tags exist at
   `ghcr.io/raktim94/rechvix-server` and `ghcr.io/raktim94/rechvix-worker`
   before updating this file — CasaOS installs will fail outright if the
   pinned tag doesn't exist yet.

## Submitting to the official CasaOS App Store

This manifest is written to be usable as-is (see "Install it right now"
above) and is also submission-ready, but submitting the actual pull
request to
[`IceWhaleTech/CasaOS-AppStore`](https://github.com/IceWhaleTech/CasaOS-AppStore)
is a deliberate, separate step — not done as part of preparing this
manifest, since it's a one-way action against someone else's public repo.
When you're ready:

1. Fork `IceWhaleTech/CasaOS-AppStore` and add a new `Apps/rechvix/`
   directory containing this directory's `docker-compose.yml`, `icon.png`,
   and `thumbnail.png`.
2. Update the `icon:` and `thumbnail:` URLs in the copied
   `docker-compose.yml` to point at the CasaOS-AppStore repo instead of
   this one, following the same jsdelivr CDN pattern every other app in
   that store uses:
   ```
   https://cdn.jsdelivr.net/gh/IceWhaleTech/CasaOS-AppStore@main/Apps/rechvix/icon.png
   ```
3. Take a couple of real screenshots of the running app (dashboard, an
   invoice, the GST/tax view) and add a `screenshot_link:` entry under
   `x-casaos:` — CasaOS App Store submissions expect at least one.
4. Open the PR against `IceWhaleTech/CasaOS-AppStore`. Their own
   `CONTRIBUTING.md` documents the current review checklist — re-check it
   at submission time, since it can change independently of this file.

Only `en_US` is filled in for the multi-locale fields (`title`, `tagline`,
`description`) — every real app in the store also supports more locales,
but translating into them is a separate, ongoing effort best done
post-submission rather than guessed at here.
