#!/usr/bin/env bash
set -euo pipefail

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required to run this script." >&2
  exit 1
fi

ADMIN_URL=${ADMIN_URL:-http://localhost:8001}
SERVICE_NAME=${SERVICE_NAME:-httpbin}
SERVICE_URL=${SERVICE_URL:-http://httpbin:80}
ROUTE_NAME=${ROUTE_NAME:-httpbin-route}
ROUTE_PATH=${ROUTE_PATH:-/httpbin}

ensure_service() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "${ADMIN_URL}/services" \
    --data name="${SERVICE_NAME}" \
    --data url="${SERVICE_URL}")

  case "${status}" in
    201)
      echo "Created service '${SERVICE_NAME}'."
      ;;
    409)
      status=$(curl -s -o /dev/null -w "%{http_code}" \
        -X PATCH "${ADMIN_URL}/services/${SERVICE_NAME}" \
        --data url="${SERVICE_URL}")
      if [[ "${status}" != "200" ]]; then
        echo "Failed to update existing service '${SERVICE_NAME}' (status ${status})." >&2
        exit 1
      fi
      echo "Updated service '${SERVICE_NAME}'."
      ;;
    *)
      echo "Failed to create service '${SERVICE_NAME}' (status ${status})." >&2
      exit 1
      ;;
  esac
}

ensure_route() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "${ADMIN_URL}/services/${SERVICE_NAME}/routes" \
    --data name="${ROUTE_NAME}" \
    --data "paths[]=${ROUTE_PATH}" \
    --data strip_path=true)

  case "${status}" in
    201)
      echo "Created route '${ROUTE_NAME}'."
      ;;
    409)
      status=$(curl -s -o /dev/null -w "%{http_code}" \
        -X PATCH "${ADMIN_URL}/routes/${ROUTE_NAME}" \
        --data "paths[]=${ROUTE_PATH}" \
        --data strip_path=true)
      if [[ "${status}" != "200" ]]; then
        echo "Failed to update existing route '${ROUTE_NAME}' (status ${status})." >&2
        exit 1
      fi
      echo "Updated route '${ROUTE_NAME}'."
      ;;
    *)
      echo "Failed to create route '${ROUTE_NAME}' (status ${status})." >&2
      exit 1
      ;;
  esac
}

ensure_service
ensure_route

echo
echo "You can now call the upstream through Kong:"
echo "  curl http://localhost:8000${ROUTE_PATH}/get"
