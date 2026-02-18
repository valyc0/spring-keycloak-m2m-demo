#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"

stop_pid_file() {
  local pid_file="$1"
  local name="$2"

  if [[ ! -f "$pid_file" ]]; then
    echo "[SKIP] PID non trovato per $name"
    return 0
  fi

  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"

  if [[ -z "$pid" ]]; then
    echo "[SKIP] PID vuoto per $name"
    rm -f "$pid_file"
    return 0
  fi

  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" || true
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" || true
    fi
    echo "[OK] Fermato $name (pid=$pid)"
  else
    echo "[SKIP] Processo già fermo per $name (pid=$pid)"
  fi

  rm -f "$pid_file"
}

echo "[1/2] Stop processi Java avviati dallo start-flow..."
stop_pid_file "$LOG_DIR/service-a-role.pid" "service-a-role"
stop_pid_file "$LOG_DIR/service-a-no-role.pid" "service-a-no-role"
stop_pid_file "$LOG_DIR/service-b.pid" "service-b"

echo "[2/2] Stop docker compose..."
cd "$ROOT_DIR"
docker compose down

echo "Stop completato"
