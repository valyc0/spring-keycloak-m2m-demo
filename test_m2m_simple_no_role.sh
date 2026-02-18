#!/usr/bin/env bash
set -euo pipefail

TOKEN=$(curl -sS -X POST "http://localhost:8190/realms/rubrica-realm/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=service-a-no-role-client" \
  -d "client_secret=service-a-no-role-secret" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')

curl -v "http://localhost:8082/api/rubrica" \
  -H "Authorization: Bearer ${TOKEN}"
