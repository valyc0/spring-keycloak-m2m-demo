local openidc = require("resty.openidc")
local cjson = require("cjson.safe")

local M = {}

local OIDC_OPTS = {
  discovery = "http://keycloak:8080/realms/rubrica-realm/.well-known/openid-configuration",
  client_id = "service-a-client",
  client_secret = "service-a-secret",
  ssl_verify = "no",
  accept_none_alg = false,
  accept_unsupported_alg = false,
  access_token_expires_leeway = 5,
}

local function write_json(status, body)
  ngx.status = status
  ngx.header.content_type = "application/json"
  ngx.say(cjson.encode(body))
  return ngx.exit(status)
end

local function has_realm_role(claims, required_role)
  local realm_access = claims and claims.realm_access
  local roles = realm_access and realm_access.roles
  if type(roles) ~= "table" then
    return false
  end

  for _, role in ipairs(roles) do
    if role == required_role then
      return true
    end
  end

  return false
end

function M.run(required_role)
  local claims, err = openidc.bearer_jwt_verify(OIDC_OPTS)
  if err then
    return write_json(401, {
      message = "Unauthorized",
      detail = err,
    })
  end

  if not has_realm_role(claims, required_role) then
    return write_json(403, {
      message = "Forbidden",
      detail = "role " .. required_role .. " is required",
    })
  end

  return
end

return M
