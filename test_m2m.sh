#!/usr/bin/env bash
set -euo pipefail

KEYCLOAK_BASE_URL="${KEYCLOAK_BASE_URL:-http://localhost:8190}"
REALM="${REALM:-rubrica-realm}"
TOKEN_URL="${KEYCLOAK_BASE_URL}/realms/${REALM}/protocol/openid-connect/token"

SERVICE_A_URL="${SERVICE_A_URL:-http://localhost:8081/api/rubrica}"
SERVICE_B_URL="${SERVICE_B_URL:-http://localhost:8082/api/rubrica}"

CLIENT_OK_ID="${CLIENT_OK_ID:-service-a-client}"
CLIENT_OK_SECRET="${CLIENT_OK_SECRET:-service-a-secret}"
CLIENT_NO_ROLE_ID="${CLIENT_NO_ROLE_ID:-service-a-no-role-client}"
CLIENT_NO_ROLE_SECRET="${CLIENT_NO_ROLE_SECRET:-service-a-no-role-secret}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Errore: comando '$1' non trovato" >&2
    exit 1
  fi
}

get_token() {
  local client_id="$1"
  local client_secret="$2"

  local response
  response="$(curl -sS --fail \
    -X POST "$TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials" \
    -d "client_id=${client_id}" \
    -d "client_secret=${client_secret}")"

  printf '%s' "$response" | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}

call_status() {
  local url="$1"
  local token="$2"
  curl -sS -o /tmp/rubrica-body.txt -w "%{http_code}" \
    -H "Authorization: Bearer ${token}" \
    "$url"
}

echo "[1/5] Verifico prerequisiti..."
require_cmd curl
require_cmd python3


echo "[2/5] Ottengo token per client CON ruolo CALL_B (${CLIENT_OK_ID})..."
TOKEN_OK="$(get_token "$CLIENT_OK_ID" "$CLIENT_OK_SECRET")"


echo "[3/5] Ottengo token per client SENZA ruolo CALL_B (${CLIENT_NO_ROLE_ID})..."
TOKEN_NO_ROLE="$(get_token "$CLIENT_NO_ROLE_ID" "$CLIENT_NO_ROLE_SECRET")"


echo "[4/5] Chiamo service-b direttamente con token CON ruolo (atteso 200)..."
STATUS_OK="$(call_status "$SERVICE_B_URL" "$TOKEN_OK")"
if [[ "$STATUS_OK" != "200" ]]; then
  echo "KO: service-b con ruolo ha risposto ${STATUS_OK} (atteso 200)"
  cat /tmp/rubrica-body.txt
  exit 1
fi

echo "[4b/5] Chiamo service-b direttamente con token SENZA ruolo (atteso 403)..."
STATUS_FORBIDDEN="$(call_status "$SERVICE_B_URL" "$TOKEN_NO_ROLE")"
if [[ "$STATUS_FORBIDDEN" != "403" ]]; then
  echo "KO: service-b senza ruolo ha risposto ${STATUS_FORBIDDEN} (atteso 403)"
  cat /tmp/rubrica-body.txt
  exit 1
fi


echo "[5/5] Chiamo service-a (A -> Keycloak -> B) con flusso machine-to-machine (atteso 200)..."
STATUS_A="$(curl -sS -o /tmp/rubrica-a-body.txt -w "%{http_code}" "$SERVICE_A_URL")"
if [[ "$STATUS_A" != "200" ]]; then
  echo "KO: service-a ha risposto ${STATUS_A} (atteso 200)"
  cat /tmp/rubrica-a-body.txt
  exit 1
fi

echo
echo "OK: test machine-to-machine completato"
echo "- service-b con CALL_B: 200"
echo "- service-b senza CALL_B: 403"
echo "- service-a -> service-b via Keycloak: 200"
