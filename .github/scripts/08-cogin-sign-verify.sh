#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   06-cosign-sign-verify.sh <SERVICE> <REGISTRY> <WORKFLOW_PATH> <BRANCH_REF>
#
# Example:
#   06-cosign-sign-verify.sh "gateway" "1234567890.dkr.ecr.us-east-1.amazonaws.com" \
#       ".github/workflows/gateway.yaml" "refs/heads/test-workflows"

SERVICE="${1:-gateway}"
REGISTRY="${2:-}"
WORKFLOW_PATH="${3:-.github/workflows/gateway.yaml}"
BRANCH_REF="${4:-refs/heads/main}"

if [ -z "$REGISTRY" ]; then
  echo "❌ Missing registry parameter" >&2
  exit 1
fi

echo "🔐 Installing Cosign..."
COSIGN_BIN="/usr/local/bin/cosign"
wget -q https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 -O cosign
sudo mv cosign "$COSIGN_BIN"
sudo chmod +x "$COSIGN_BIN"
cosign version || echo "⚠️ Cosign installed, version check failed."

echo "🪪 Signing Docker image (${REGISTRY}/${SERVICE}:latest) using keyless OIDC..."
export COSIGN_EXPERIMENTAL=1

cosign sign "${REGISTRY}/${SERVICE}:latest" \
  --yes || { echo "❌ Cosign signing failed"; exit 1; }

echo "🧾 Verifying Cosign signature..."
cosign verify \
  --certificate-identity "https://github.com/${GITHUB_REPOSITORY}/${WORKFLOW_PATH}@${BRANCH_REF}" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  "${REGISTRY}/${SERVICE}:latest"

echo "✅ Cosign signing and verification completed successfully."