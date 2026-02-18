#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"

mkdir -p "$LOG_DIR"

free_port_if_busy() {
  local port="$1"
  local name="$2"

  local pid
  pid="$(ss -ltnp 2>/dev/null | sed -n "s/.*:${port} .*pid=\([0-9]\+\).*/\1/p" | head -n1)"
  if [[ -n "$pid" ]]; then
    echo "[WARN] Porta ${port} occupata (${name}), termino pid=$pid"
    kill "$pid" || true
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" || true
    fi
  fi
}

wait_http() {
  local url="$1"
  local name="$2"
  local retries="${3:-60}"

  for _ in $(seq 1 "$retries"); do
    local status
    status="$(curl -s -o /dev/null -w "%{http_code}" "$url" || true)"
    if [[ "$status" != "000" ]]; then
      echo "[OK] $name raggiungibile ($status)"
      return 0
    fi
    sleep 1
  done

  echo "[KO] Timeout attesa $name su $url"
  return 1
}

start_bg() {
  local dir="$1"
  local cmd="$2"
  local log_file="$3"
  local pid_file="$4"

  (
    cd "$dir"
    nohup bash -lc "$cmd" > "$log_file" 2>&1 &
    echo $! > "$pid_file"
  )
}

assert_process_alive() {
  local pid_file="$1"
  local name="$2"

  if [[ ! -f "$pid_file" ]]; then
    echo "[KO] PID file non creato per ${name}: $pid_file"
    exit 1
  fi

  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -z "$pid" ]] || ! kill -0 "$pid" 2>/dev/null; then
    echo "[KO] ${name} non è in esecuzione dopo lo start"
    exit 1
  fi
}

echo "[0/6] Cleanup run precedente..."
cd "$ROOT_DIR"
if [[ -x "./stop-flow.sh" ]]; then
  ./stop-flow.sh || true
fi

free_port_if_busy 8081 "service-a-role"
free_port_if_busy 8082 "service-b"
free_port_if_busy 8083 "service-a-no-role"

echo "[1/6] Start docker compose..."
cd "$ROOT_DIR"
./start-docker-compose.sh
wait_http "http://localhost:8190/realms/rubrica-realm/.well-known/openid-configuration" "Keycloak" 90

echo "[2/6] Start service-b in background..."
start_bg "$ROOT_DIR/service-b" "./service-b-start.sh" "$LOG_DIR/service-b.log" "$LOG_DIR/service-b.pid"
sleep 2
assert_process_alive "$LOG_DIR/service-b.pid" "service-b"
wait_http "http://localhost:8082/api/rubrica" "service-b" 90

echo "[3/6] Start service-a NO ROLE in background..."
start_bg "$ROOT_DIR/service-a" "./service-a-no-role.sh" "$LOG_DIR/service-a-no-role.log" "$LOG_DIR/service-a-no-role.pid"
sleep 2
assert_process_alive "$LOG_DIR/service-a-no-role.pid" "service-a-no-role"
wait_http "http://localhost:8083/api/rubrica" "service-a-no-role" 90

echo "[4/6] Verifica errore atteso su service-a NO ROLE..."
STATUS_NO_ROLE="$(curl -s -o "$LOG_DIR/service-a-no-role-response.json" -w "%{http_code}" "http://localhost:8083/api/rubrica" || true)"
if [[ "$STATUS_NO_ROLE" != "403" ]]; then
  echo "[KO] service-a-no-role ha risposto ${STATUS_NO_ROLE}, atteso 403"
  exit 1
fi
echo "[OK] service-a-no-role ha risposto con errore atteso (403)"

echo "[5/6] Start service-a ROLE in background..."
start_bg "$ROOT_DIR/service-a" "./service-a-role.sh" "$LOG_DIR/service-a-role.log" "$LOG_DIR/service-a-role.pid"
sleep 2
assert_process_alive "$LOG_DIR/service-a-role.pid" "service-a-role"
wait_http "http://localhost:8081/api/rubrica" "service-a-role" 90

echo "[6/6] Verifica successo su service-a ROLE..."
STATUS_ROLE="$(curl -s -o "$LOG_DIR/service-a-role-response.json" -w "%{http_code}" "http://localhost:8081/api/rubrica" || true)"
if [[ "$STATUS_ROLE" != "200" ]]; then
  echo "[KO] service-a-role ha risposto $STATUS_ROLE, atteso 200"
  echo "Controlla log: $LOG_DIR/service-a-role.log"
  exit 1
fi

echo "[OK] service-a-role ha risposto 200"
echo
echo "Flow completato"
echo "Log: $LOG_DIR"
echo "PID file: $LOG_DIR/*.pid"
