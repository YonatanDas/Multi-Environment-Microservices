#!/usr/bin/env bash
# Get service configuration from services.yaml
# Usage: .github/scripts/00-get-service-config.sh <service_name> <config_key>
# Example: .github/scripts/00-get-service-config.sh accounts path

set -euo pipefail

SERVICE="${1:-}"
CONFIG_KEY="${2:-}"

if [[ -z "${SERVICE}" || -z "${CONFIG_KEY}" ]]; then
  echo "Usage: $0 <service_name> <config_key>" >&2
  echo "Config keys: path, helm_name, dockerfile, service_account_name, port" >&2
  exit 1
fi

CONFIG_FILE=".github/config/services.yaml"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "Error: ${CONFIG_FILE} not found" >&2
  exit 1
fi

# Use yq to extract the value (if available) or use a simple grep/sed approach
if command -v yq &> /dev/null; then
  yq eval ".services.${SERVICE}.${CONFIG_KEY}" "${CONFIG_FILE}" 2>/dev/null || echo ""
else
  # Fallback: simple grep/sed (less robust but works without yq)
  grep -A 10 "^  ${SERVICE}:" "${CONFIG_FILE}" | grep "^\s*${CONFIG_KEY}:" | sed "s/.*${CONFIG_KEY}:\s*\(.*\)/\1/" | tr -d '"' || echo ""
fi

