# Vaultwarden - Self-Hosted Deployment

Vaultwarden deployment config for `servidor-ubuntu-home`, accessible exclusively via Tailscale.

## Access

- **URL**: `https://servidor-ubuntu-home.tail2f0857.ts.net`
- **Network**: Tailscale only (no public exposure)
- **Caddy**: Reverse proxy with internal TLS

## Tech Stack

- **Vaultwarden** (bitwarden-rs fork) — lightweight password manager server
- **Caddy** — automatic HTTPS reverse proxy
- **SQLite** — single-file database (no Postgres needed)

## Quick Start

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

## Backup

```bash
./scripts/backup.sh
```

Backups go to `~/Documentos/Mega/alefe-vaultwarden-backup/`, rotated after 30 days.
