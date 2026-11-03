# KinetiRx on CasaOS / ZimaOS

This directory holds the app store manifest and assets that let KinetiRx
install as a one-click app on [CasaOS](https://casaos.io) and
[ZimaOS](https://zimaspace.com) (ZimaOS uses the identical `x-casaos`
compose schema).

| File | Purpose |
| --- | --- |
| `docker-compose.yml` | The app manifest itself — standard Compose plus a top-level `x-casaos:` block CasaOS reads to render the store listing and install form. |
| `icon.png` | 256×256 square app icon. |
| `thumbnail.png` | Store-listing banner. |
| `screenshot-1.png` … `screenshot-5.png` | Dashboard, POS, Inventory, Patients, and Due-Khata — the same images used in the main [README](../README.md#screenshots). |

## Install it right now (before official app store approval)

CasaOS and ZimaOS can both install directly from a compose file URL — you
don't need to wait for this to land in the official app store:

1. In CasaOS/ZimaOS, go to **App Store → + (top right) → Install a customized app** (CasaOS) or the equivalent **Custom Install / Install via Compose** option in ZimaOS.
2. Paste this URL:

   ```
   https://raw.githubusercontent.com/Raktim94/KinetiRx/main/casaos/docker-compose.yml
   ```

   Pasting the raw file *contents* instead of the URL also works, but paste
   from the [raw view](https://raw.githubusercontent.com/Raktim94/KinetiRx/main/casaos/docker-compose.yml),
   not GitHub's syntax-highlighted file view — copying from the highlighted
   view can silently substitute non-breaking spaces for the YAML indentation,
   which fails CasaOS's paste validation with a generic "Please confirm the
   input content" error instead of installing. `release_notes` is kept to
   just the current version (see [CHANGELOG.md](../CHANGELOG.md) for full
   history) partly to keep this paste short enough not to trip that path.
3. Install. CasaOS pulls the pre-built `ghcr.io/raktim94/kinetirx-backend`
   and `ghcr.io/raktim94/kinetirx-frontend` images — there is no build step,
   so it works even though CasaOS never touches this repo's source. **Both
   images must be public on ghcr.io** for this to succeed; a private image
   fails the pull with an unauthorized error and the app never starts.
4. Open it from the CasaOS dashboard, or go straight to
   `http://<your-casaos-box>:3080`. On first visit you'll land on a
   "Create Admin Account" screen — name + password, no manual configuration
   needed. There is no password-reset flow, so keep the password safe.
   (`KINETIRX_ADMIN_PASSWORD` is left blank in this manifest on purpose so
   the screen shows up; setting it before install pre-seeds employee ID
   `EMP-ADMIN-1` instead and skips the screen.)

Your data (the Postgres database) persists at
`/DATA/AppData/kinetirx/postgres` on the CasaOS box, following the same
convention CasaOS's own backup/restore UI expects for every other app.

## No secret is auto-generated — change the defaults

Unlike some other Nodedr apps, KinetiRx's backend deliberately has no
fallback/default for `JWT_SECRET` or the Postgres password baked into the
app itself (see `backend/internal/config/config.go` — "no hardcoded
secrets... for anything security-sensitive" is the stated design). CasaOS
also has no mechanism to auto-generate a value for you at install time
(verified against 189 real apps already in the store — none do this).  So
this manifest ships **real default values** for the Postgres password and
JWT secret, each flagged in its own field description and in the
install-time `tips.before_install` notice. Change both before using this
beyond a local trial — leaving them as-is is fine for kicking the tyres on
your LAN, not for anything internet-facing. The admin account has no such
default — it's created from the app's own first-run signup screen instead
(see "Install it right now" above).

## Why three containers

KinetiRx is a three-container app (`postgres` + `backend` + `frontend`),
same as the plain [`docker-compose.yml`](../deploy/docker-compose.yml) at
`deploy/` — see [Architecture](../README.md#architecture) for why. The
manifest declares `main: frontend` since that's the browsable
service; CasaOS uses this to know which container's port to open when you
click the app.

## Publishing new image versions

`docker-compose.yml` here pins exact image tags (CasaOS requires pinned,
not `:latest`, tags). To publish a new version:

1. Bump the version everywhere it's referenced — the two `image:` tags in
   this file, `version:` and `update_at:` under `x-casaos:`, and
   `release_notes.en_US` (replace it with just the new version's note —
   don't append to the history here, add the full entry to
   [`../CHANGELOG.md`](../CHANGELOG.md) instead; keeping this field short
   is what keeps the paste-content install path working).
2. Build and push both images multi-arch (`linux/amd64` **and**
   `linux/arm64` — a lot of CasaOS/ZimaOS boxes are ARM SBCs), e.g.:
   ```
   docker buildx build --platform linux/amd64,linux/arm64 \
     -t ghcr.io/raktim94/kinetirx-backend:<version> \
     -f backend/Dockerfile backend --push
   ```
   (and the equivalent for `frontend/Dockerfile`).
3. Confirm both new tags exist at `ghcr.io/raktim94/kinetirx-backend` and
   `ghcr.io/raktim94/kinetirx-frontend`, and that **both packages are set
   to public visibility** (Package settings → Danger Zone → Change
   visibility — GitHub's API cannot do this for a personal-account package,
   only the web UI can), before updating this file. CasaOS installs fail
   outright if the pinned tag doesn't exist or isn't publicly pullable.

## Submitting to the official CasaOS App Store

This manifest is written to be usable as-is (see "Install it right now"
above) and is also submission-ready, but submitting the actual pull request
to
[`IceWhaleTech/CasaOS-AppStore`](https://github.com/IceWhaleTech/CasaOS-AppStore)
is a deliberate, separate step:

1. Fork `IceWhaleTech/CasaOS-AppStore` and add a new `Apps/KinetiRx/`
   directory containing this directory's `docker-compose.yml`, `icon.png`,
   `thumbnail.png`, and the `screenshot-*.png` files.
2. Update the `icon:`, `thumbnail:`, and `screenshot_link:` URLs in the
   copied `docker-compose.yml` to point at the CasaOS-AppStore repo instead
   of this one, following the same jsdelivr CDN pattern every other app in
   that store uses:
   ```
   https://cdn.jsdelivr.net/gh/IceWhaleTech/CasaOS-AppStore@main/Apps/KinetiRx/icon.png
   ```
3. Open the PR against `IceWhaleTech/CasaOS-AppStore`. Their own
   `CONTRIBUTING.md` documents the current review checklist — re-check it
   at submission time, since it can change independently of this file.

(This has already been done once — see PR status linked from the main
[README](../README.md#self-hosting-on-casaos--zimaos).)

Only `en_US` is filled in for the multi-locale fields (`title`, `tagline`,
`description`, `release_notes`) — every real app in the store also
supports more locales, but translating into them is a separate, ongoing
effort best done post-submission rather than guessed at here.
