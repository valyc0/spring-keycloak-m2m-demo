#!/usr/bin/env bash
set -euo pipefail

TOKEN=$(curl -sS -X POST \
  "http://localhost:8190/realms/rubrica-realm/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=service-a-client" \
  -d "client_secret=service-a-secret" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

if [[ -z "${TOKEN}" ]]; then
  echo "Errore: token non ottenuto da Keycloak"
  exit 1
fi

curl -sS -i "http://localhost:9080/hello-myworld" \
  -H "Authorization: Bearer ${TOKEN}"
