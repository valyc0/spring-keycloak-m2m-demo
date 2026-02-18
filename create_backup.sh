#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

BACKUP_DIR="$(dirname "$PROJECT_DIR")/backup"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
ARCHIVE_NAME="${PROJECT_NAME}_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

mkdir -p "$BACKUP_DIR"

cd "$PROJECT_DIR"

tar -czf "$ARCHIVE_PATH" \
  --exclude='*/target' \
  --exclude='*/.git' \
  --exclude='*/.idea' \
  --exclude='*/.vscode' \
  --exclude='*/node_modules' \
  --exclude='*.log' \
  --exclude='backup' \
  .

echo "Backup creato: $ARCHIVE_PATH"
