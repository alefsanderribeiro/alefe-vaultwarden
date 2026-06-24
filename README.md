# alefe-vaultwarden — Self-hosted Vaultwarden (Bitwarden-compatible) password manager

## Overview

Deployment configuration for [Vaultwarden](https://github.com/dani-garcia/vaultwarden), a lightweight Bitwarden-compatible API server written in Rust. Accessible exclusively via Tailscale VPN, secured by Caddy reverse proxy with automatic HTTPS via Cloudflare DNS-01 challenge, and backed up daily to Mega.nz. Intended for private/family use — no ports exposed to the public internet.

## Architecture

```
Browser/App -> Tailscale -> UFW -> Caddy:443 -> Vaultwarden:80 -> SQLite
                                                      |
                                                  Cloudflare DNS-01
                                                      |
                                                  Let's Encrypt TLS
```

All traffic flows through Tailscale's WireGuard mesh network. Caddy listens on port 443 (Tailscale interface only) and terminates TLS using certificates obtained via Cloudflare DNS-01 ACME challenge. Vaultwarden listens on port 80 internally — never exposed directly.

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Vaultwarden | docker: v1.36.0 | Bitwarden-compatible API server |
| Caddy | custom with caddy-dns/cloudflare | Reverse proxy, automatic HTTPS |
| Tailscale | WireGuard mesh VPN | Private network overlay |
| Cloudflare | DNS-01 ACME | TLS certificate validation |
| SQLite | Single file | Password database |
| UFW | Firewall | Block public access |

## Prerequisites

- Ubuntu server (or any Linux with Docker)
- Docker and Docker Compose plugin installed
- Tailscale installed and authenticated
- A domain with DNS managed by Cloudflare (e.g., `vault.yourdomain.com`)
- Cloudflare API token with `Zone:DNS:Edit` permission
- Mega.nz account (for automated off-site backups — optional)

## Quick Start

```bash
git clone https://github.com/alefsanderribeiro/alefe-vaultwarden.git
cd alefe-vaultwarden
cp .env.example .env
# Edit .env with your values (see Environment Variables below)
./scripts/install.sh
```

## Step-by-Step Deployment

1. **Clone the repository**

   ```bash
   git clone https://github.com/alefsanderribeiro/alefe-vaultwarden.git
   cd alefe-vaultwarden
   ```

2. **Configure environment**

   ```bash
   cp .env.example .env
   chmod 600 .env
   ```

   Edit `.env` with your values. At minimum:
   - `DOMAIN` — your Vaultwarden URL (e.g., `https://vault.yourdomain.com`)
   - `ADMIN_TOKEN` — generate with `openssl rand -base64 48`
   - `CF_API_TOKEN` — Cloudflare API token (see step 3)
   - SMTP settings — required for email verification on signup

3. **Create Cloudflare API token**

   - Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
   - Go to **My Profile > API Tokens > Create Token**
   - Use the **Edit zone DNS** template
   - Permissions: `Zone > DNS > Edit`
   - Zone Resources: `Include > Specific zone > yourdomain.com`
   - Copy the token and set as `CF_API_TOKEN` in `.env`

4. **Configure DNS record**

   - In Cloudflare DNS, create an **A record** for `vault.yourdomain.com`
   - Point it to your server's **Tailscale IP** (e.g., `100.x.x.x`)
   - Set the proxy status to **DNS only (grey cloud)** — no proxying

5. **Run installation**

   ```bash
   ./scripts/install.sh
   ```

   This script:
   - Creates required directories (`vw-data`, `caddy-data`, `caddy-config`)
   - Pulls Docker images
   - Starts containers via `docker compose up -d`
   - Waits for the healthcheck endpoint

6. **Configure UFW firewall**

   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow in on tailscale0 to any port 443
   sudo ufw allow 22/tcp          # SSH
   sudo ufw enable
   ```

   This blocks all ports except SSH and Tailscale traffic on 443.

7. **Set up backup cron**

   ```bash
   crontab -e
   ```

   Add the following line (runs daily at 3 AM):

   ```cron
   0 3 * * * /home/your-user/vaultwarden/scripts/backup.sh
   ```

   Automated backups sync to Mega.nz via the Mega desktop client or `megacmd` CLI.

8. **Access the admin panel**

   Navigate to `https://vault.yourdomain.com/admin` and enter your admin token to manage users, enable/disable signups, and view diagnostic information.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DOMAIN` | Yes | — | Public URL for the vault (e.g., `https://vault.alefsander.dev`) |
| `ADMIN_TOKEN` | Yes | — | Admin panel access token. Generate with `openssl rand -base64 48` |
| `CF_API_TOKEN` | Yes | — | Cloudflare API token with Zone:DNS:Edit permissions |
| `DATA_FOLDER` | No | `/data` | Path to SQLite database directory inside container |
| `ATTACHMENTS_FOLDER` | No | `/data/attachments` | File attachment storage path |
| `SENDS_FOLDER` | No | `/data/sends` | Bitwarden Send file storage path |
| `SENDS_ALLOWED` | No | `true` | Enable/disable Bitwarden Send feature |
| `ENABLE_WEBSOCKET` | No | `true` | Enable WebSocket for real-time vault sync |
| `SIGNUPS_ALLOWED` | No | `true` | Allow new user registration (disable after family is onboarded) |
| `SIGNUPS_VERIFY` | No | `true` | Require email verification for new accounts |
| `ROCKET_ADDRESS` | No | `0.0.0.0` | Vaultwarden internal bind address |
| `ROCKET_PORT` | No | `80` | Vaultwarden internal port |
| `SMTP_HOST` | Conditional | — | SMTP server hostname (required if SIGNUPS_VERIFY is true) |
| `SMTP_FROM` | Conditional | — | From address for outgoing emails |
| `SMTP_FROM_NAME` | No | `Vaultwarden` | Display name for outgoing emails |
| `SMTP_PORT` | No | `587` | SMTP server port |
| `SMTP_SECURITY` | No | `starttls` | SMTP security method (`starttls` or `tls`) |
| `SMTP_USERNAME` | Conditional | — | SMTP authentication username |
| `SMTP_PASSWORD` | Conditional | — | SMTP authentication password (use app password for Gmail) |

## Security Architecture

Each layer serves a specific purpose in defense in depth:

- **Tailscale VPN** — WireGuard-encrypted mesh network. Only devices authenticated to your tailnet can reach the server. No ports exposed to the public internet. Tailscale IPs are stable and routable across NATs.

- **Caddy HTTPS** — Reverse proxy terminates TLS using certificates obtained via Cloudflare DNS-01 challenge. Because the domain is DNS-only (grey cloud), Cloudflare never sees the traffic — only the Let's Encrypt ACME validation hits Cloudflare's API. No public ports are required for certificate renewal.

- **UFW firewall** — Default deny ingress. Only port 22 (SSH) and port 443 on the `tailscale0` interface are open. Port 80 is not exposed — ACME does not need it because DNS-01 is used.

- **Secrets management** — `.env` is gitignored and has `chmod 600`. The admin token and Cloudflare API token never appear in version control or container layers.

- **Admin token** — A high-entropy Base64 token used for the `/admin` panel. Without it, the admin interface is inaccessible.

## Backup & Restore

### Backup

The `scripts/backup.sh` script runs daily via cron (3 AM) and:

1. Creates a consistent SQLite snapshot using `.backup` (safe for live databases)
2. Runs `PRAGMA integrity_check` on the copy — exits with code 2 if integrity fails
3. Copies attachments, sends, config, and RSA keys
4. Compresses everything into a timestamped `.tar.gz` archive
5. Rotates backups older than 30 days

Backups are written to `~/Documentos/Mega/alefe-vaultwarden-backup/` and automatically synced to Mega.nz by the Mega desktop client or `megacmd`.

Backup contents:
- `db.sqlite3` — encrypted password database
- `attachments/` — file attachments
- `sends/` — Bitwarden Send data
- `config.json` — Vaultwarden configuration
- `rsa_key` / `rsa_key.pub` — encryption keys

### Restore

See [docs/RESTORE.md](docs/RESTORE.md) for the full restore procedure. Summary:

```bash
docker compose down
mv vw-data vw-data-old
mkdir vw-data
tar -xzf /path/to/backup/vw-<TIMESTAMP>.tar.gz -C vw-data/
sqlite3 vw-data/db.sqlite3 "PRAGMA integrity_check;"
chmod -R 700 vw-data
docker compose up -d
```

## Maintenance

```bash
# Update Vaultwarden
docker compose pull vaultwarden
docker compose up -d vaultwarden

# Check logs
docker compose logs vaultwarden --tail=30
docker compose logs caddy --tail=30

# Verify backup integrity
cd /path/to/backup/dir && tar -tzf vw-*.tar.gz | head

# Restart services
docker compose restart

# Full rebuild
docker compose down && docker compose up -d
```

## Client Configuration

Vaultwarden is fully compatible with official Bitwarden clients. Configure each client:

1. Install the **Bitwarden** app (not Vaultwarden) for your platform
2. Go to **Settings > Self-hosted environment** (or "Server URL")
3. Set the server URL to `https://vault.yourdomain.com`
4. Log in with your email and master password

**Important**: The device must be connected to Tailscale for the domain to resolve.

### Supported clients

- [Bitwarden Web Vault](https://vault.yourdomain.com) (built-in)
- [Bitwarden Browser Extension](https://bitwarden.com/download/) (Chrome, Firefox, Edge)
- [Bitwarden Desktop App](https://bitwarden.com/download/)
- [Bitwarden Mobile App](https://bitwarden.com/download/) (Android, iOS)
- [Bitwarden CLI](https://bitwarden.com/help/cli/)

## Advantages

- **Complete privacy** — no third-party server ever sees your passwords. Zero-knowledge encryption end to end.
- **Zero cost** — no subscription fees. The only costs are your domain (a few dollars/year) and Cloudflare's free tier.
- **Bitwarden compatible** — works with every official Bitwarden client on every platform.
- **Full control** — admin panel, user management, password sharing, 2FA enforcement, event logs.
- **Automatic backups** — daily encrypted backups automatically synced to the cloud.
- **Secure by design** — Tailscale-only access means no attack surface on the public internet. No ports to scan, no bots to fight.
- **Family ready** — share passwords, notes, and payment cards across family members with controlled collections.

## Disadvantages / Considerations

- **No master password recovery** — if the master password is lost, the vault is permanently inaccessible. There is no backdoor.
- **Tailscale dependency** — every user must have Tailscale installed and authenticated on every device that needs vault access.
- **Self-hosted maintenance** — you are responsible for updates, backups, and uptime. Plan for occasional maintenance windows.
- **SQLite scaling limits** — SQLite handles concurrent writes via a lock. Suitable for families (under 10 concurrent users). For larger teams, consider Postgres-backed alternatives.
- **SMTP required** — email verification, invitations, and password hints require a working SMTP configuration. Gmail app passwords work reliably.

## Troubleshooting

| Problem | Likely cause | Solution |
|---------|-------------|----------|
| Caddy can't get certificate | CF_API_TOKEN lacks DNS:Edit permission | Verify token permissions in Cloudflare dashboard. Test with a manual DNS record add. |
| Can't access web vault | Tailscale not connected or UFW blocking | Run `tailscale status` to verify connectivity. Check `sudo ufw status` for rules. |
| Can't reach vault in browser | DNS not resolving | Verify DNS A record points to Tailscale IP (grey cloud). Test with `dig vault.yourdomain.com`. |
| Extension can't connect | Server URL set incorrectly | Must be `https://vault.yourdomain.com` (with protocol, no trailing slash) |
| SMTP not sending | Wrong credentials or blocked | Use Gmail app password (not account password). Check SMTP logs with `docker compose logs vaultwarden`. |
| 502 Bad Gateway | Vaultwarden container down | Run `docker compose ps` and `docker compose logs vaultwarden --tail=20`. |
| Signup not working | SIGNUPS_ALLOWED or SIGNUPS_VERIFY misconfigured | Check `.env` values. If SIGNUPS_VERIFY is true, SMTP must be configured. |
| Backup failing | sqlite3 not installed | Install with `sudo apt install sqlite3`. Verify backup script paths. |
