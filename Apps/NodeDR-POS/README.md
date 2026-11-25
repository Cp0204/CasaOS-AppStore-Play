# NodeDR POS on CasaOS / ZimaOS

This directory holds the app store manifest and assets that let NodeDR POS
install as a one-click app on [CasaOS](https://casaos.io) and
[ZimaOS](https://zimaspace.com) (ZimaOS uses the identical `x-casaos`
compose schema).

| File | Purpose |
| --- | --- |
| `docker-compose.yml` | The app manifest itself — standard Compose plus a top-level `x-casaos:` block CasaOS reads to render the store listing and install form. |
| `icon.png` | 512×512 square app icon. |
| `thumbnail.png` | 1568×884 store-listing banner. |
| `screenshot-1.png` … `screenshot-3.png` | Dashboard, POS checkout, and Inventory — the same images used in the main [README](../README.md#screenshots). |

## Install it right now (before official app store approval)

CasaOS and ZimaOS can both install directly from a compose file URL —
you don't need to wait for this to land in the official app store:

1. In CasaOS/ZimaOS, go to **App Store → + (top right) → Install a customized app** (CasaOS) or the equivalent **Custom Install / Install via Compose** option in ZimaOS.
2. Paste this URL (or the raw file contents):

   ```
   https://raw.githubusercontent.com/Raktim94/nodedr-pos/master/casaos/docker-compose.yml
   ```

3. Install. CasaOS pulls the pre-built `ghcr.io/raktim94/nodedr-pos-backend`
   and `ghcr.io/raktim94/nodedr-pos-frontend` images — there is no build
   step, so it works even though CasaOS never touches this repo's source.
4. Open it from the CasaOS dashboard, or go straight to
   `http://<your-casaos-box>:1994`. First launch walks you through creating
   an admin account and setting up your shop, exactly like every other
   install method.

**Updating:** admins get an "Update available" banner in the app. Open
**Settings → Updates → Update now** — the bundled `nodedr-pos-updater`
container downloads the new version and restarts the app (about a minute).
Your data is untouched. (It needs the Docker socket, which is why the
install form lists it.)

Your data (the SQLite database) persists at
`/DATA/AppData/nodedr-pos/data` on the CasaOS box, following the same
convention CasaOS's own backup/restore UI expects for every other app.

## Why two containers, and why USB device access

NodeDR POS is a two-container app (`backend` + `frontend`), same as the
plain [`docker-compose.yml`](../docker-compose.yml) at the repo root — see
[Architecture](../README.md#architecture) for why. The manifest declares
`main: frontend` since that's the browsable service; CasaOS uses this to
know which container's port to open when you click the app.

The backend's `/dev/bus/usb` bind mount and `device_cgroup_rules` are for
**optional** direct-USB thermal receipt printing (see
[Barcode scanner](../README.md#barcode-scanner) and
[Printing & receipts](../README.md#printing--receipts) in the main README).
Nothing breaks if no printer is attached — receipts just print via the
browser dialog or download as a PDF instead. The cgroup rules are scoped to
exactly the two USB device majors printing needs (`189` usbfs, `180`
usblp), not full `privileged: true`, so the container still can't see or
touch anything else on the host.

## Publishing new image versions

`docker-compose.yml` here pins exact image tags (CasaOS requires pinned,
not `:latest`, tags). To publish a new version:

1. Bump the version everywhere it's referenced — the two `image:` tags in
   this file, `version:` and `update_at:` under `x-casaos:`, and
   `release_notes.en_US`.
2. Run the **Publish Docker images** workflow
   (`.github/workflows/docker-publish.yml`) via `workflow_dispatch` with
   that version, or just push to `master` — it also tags a build from the
   latest git tag automatically. It builds both images for `linux/amd64`
   **and** `linux/arm64` (a lot of CasaOS/ZimaOS boxes are ARM SBCs) and
   pushes them to GHCR.
3. Confirm both new tags exist at
   `ghcr.io/raktim94/nodedr-pos-backend` and `ghcr.io/raktim94/nodedr-pos-frontend`
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

1. Fork `IceWhaleTech/CasaOS-AppStore` and add a new `Apps/NodeDR-POS/`
   directory containing this directory's `docker-compose.yml`, `icon.png`,
   `thumbnail.png`, and the `screenshot-*.png` files.
2. Update the `icon:`, `thumbnail:`, and `screenshot_link:` URLs in the
   copied `docker-compose.yml` to point at the CasaOS-AppStore repo instead
   of this one, following the same jsdelivr CDN pattern every other app in
   that store uses:
   ```
   https://cdn.jsdelivr.net/gh/IceWhaleTech/CasaOS-AppStore@main/Apps/NodeDR-POS/icon.png
   ```
3. Open the PR against `IceWhaleTech/CasaOS-AppStore`. Their own
   `CONTRIBUTING.md` documents the current review checklist — re-check it
   at submission time, since it can change independently of this file.

Only `en_US` is filled in for the multi-locale fields (`title`, `tagline`,
`description`, `release_notes`) — every real app in the store also
supports more locales, but translating into them is a separate, ongoing
effort best done post-submission rather than guessed at here.

## Troubleshooting: "there are ports in use" (port 1994)

CasaOS refuses to install if port 1994 or the container names
(`nodedr-pos-frontend`, `-backend`, `-updater`) are already taken. The usual
cause is **orphan containers**: CasaOS has forgotten the app (it is missing
from `casaos-cli app-management list apps` and `/var/lib/casaos/apps/nodedr-pos`
is gone) but the old containers are still running, for example after an
interrupted uninstall or update.

Check:

```bash
docker ps -a --filter name=nodedr-pos --format '{{.Names}} {{.Image}} {{.Ports}}'
ss -ltnp | grep :1994
```

Fix (your data lives in `/DATA/AppData/nodedr-pos/data`, a bind mount that
survives container removal — back it up first anyway):

```bash
cp -a /DATA/AppData/nodedr-pos/data ~/nodedr-pos-data-backup
docker rm -f nodedr-pos-frontend nodedr-pos-backend nodedr-pos-updater
docker network rm nodedr-pos_nodedr-pos
```

Then install NodeDR POS again from the app store.
