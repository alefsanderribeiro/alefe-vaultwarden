#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

echo "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "Docker not found"; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || echo "Warning: sqlite3 not found"

echo "Creating directories..."
mkdir -p vw-data caddy-data caddy-config
chmod 700 vw-data
chmod 600 .env

echo "Pulling images..."
docker compose pull

echo "Starting containers..."
docker compose up -d

echo "Waiting for healthcheck..."
for i in $(seq 1 10); do
    if curl -sf http://localhost:8080/alive > /dev/null 2>&1; then
        echo "Vaultwarden is running!"
        docker compose ps
        exit 0
    fi
    sleep 2
done

echo "ERROR: Vaultwarden did not start properly"
docker compose logs vaultwarden --tail=20
exit 1
