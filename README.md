# Demo M2M con Keycloak, Service A e Service B

Questo progetto mostra una comunicazione **machine-to-machine** tra due microservizi Spring Boot usando **Keycloak** come Identity Provider.

## Obiettivo

- `service-a` ottiene un token da Keycloak con `client_id` + `client_secret` (grant `client_credentials`)
- `service-a` chiama `service-b` passando il bearer token
- `service-b` valida il JWT e autorizza solo chi ha il ruolo `CALL_B`

## Componenti

- `docker-compose.yml`: avvio Keycloak
- `keycloak/realm-rubrica.json`: realm, client e ruoli
- `service-a`: client OAuth2 che inoltra la chiamata verso `service-b`
- `service-b`: resource server JWT, endpoint protetto con ruolo

## Flusso autorizzativo

1. Client M2M (service-a-role) richiede token a Keycloak
2. Keycloak emette access token JWT
3. `service-a` usa il token per chiamare `service-b`
4. `service-b` verifica issuer/firma/token e ruoli
5. Se presente `CALL_B` -> `200` con dati rubrica, altrimenti `403`

## Porte

- Keycloak: `8190`
- Service B: `8082`
- Service A role: `8081`
- Service A no-role (profilo `no-role`): `8083`

## Client Keycloak usati

- `service-a-client` / `service-a-secret` -> con ruolo `CALL_B`
- `service-a-no-role-client` / `service-a-no-role-secret` -> senza ruolo

## Convenzioni configurazione sicurezza

Per ridurre accoppiamento con un IdP specifico, la configurazione applicativa usa prefissi generici.

- `service-a`:
   - `app.security.oauth2.client-registration-id`
   - `app.security.oauth2.principal`
   - registrazione OAuth2 sotto `spring.security.oauth2.client.registration.m2m.*`
   - provider token sotto `spring.security.oauth2.client.provider.m2m.*`

- `service-b`:
   - `app.security.idp.issuer-uri`
   - `app.security.idp.role-claim-paths`
   - `app.security.idp.authority-prefix`
   - `spring.security.oauth2.resourceserver.jwt.issuer-uri=${app.security.idp.issuer-uri}`

## Script utili

### Avvio/Stop infrastruttura

- `./start-docker-compose.sh` -> `docker compose up -d`
- `./stop-flow.sh` -> stop processi Java del flow + `docker compose down`

### Avvio servizi

- `service-a/service-a-role.sh` -> avvia Service A role (porta 8081)
- `service-a/service-a-no-role.sh` -> avvia Service A no-role (porta 8083)
- `service-b/service-b-start.sh` -> avvia Service B (porta 8082)

### Flow end-to-end automatico

- `./start-flow.sh`
  - avvia compose
  - avvia `service-b`
  - avvia `service-a-no-role` e verifica `403`
  - avvia `service-a-role` e verifica `200`

## Script test semplici

- `./test_m2m_simple.sh`
  - token con client role
  - chiamata verbose a `service-b`
  - atteso: `HTTP 200`

- `./test_m2m_simple_no_role.sh`
  - token con client no-role
  - chiamata verbose a `service-b`
  - atteso: `HTTP 403`

## Avvio rapido (manuale)

1. Avvia Keycloak
   - `./start-docker-compose.sh`
2. Avvia Service B
   - `cd service-b && ./service-b-start.sh`
3. Avvia Service A role
   - `cd service-a && ./service-a-role.sh`
4. Test role
   - `cd .. && ./test_m2m_simple.sh`
5. Test no-role
   - `./test_m2m_simple_no_role.sh`

## Note

- `service-a` è volutamente senza DB locale: agisce solo da caller verso `service-b`
- nel profilo `no-role` di `service-a`, la chiamata verso `service-b` restituisce `403`
- il converter ruoli su `service-b` è generico (`IdpRoleConverter`) con claim path configurabili
