#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# SmartCow Tracker — Backup manual de PostgreSQL
# Uso: ./scripts/backup-db.sh
# ─────────────────────────────────────────────────────────────────────────────

BACKUP_DIR="backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT="${BACKUP_DIR}/db-${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "Generando backup de PostgreSQL..."
docker compose exec -T postgres \
  pg_dump -U "${POSTGRES_USER:-smartcow}" "${POSTGRES_DB:-smartcow_db}" \
  | gzip > "$OUTPUT"

echo "Backup guardado en: $OUTPUT"
