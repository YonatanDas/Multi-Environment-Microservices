#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-}"
REGISTRY="${2:-}"
AWS_REGION="${3:-us-east-1}"

if [[ -z "$SERVICE" || -z "$REGISTRY" ]]; then
  echo "❌ Usage: $0 <SERVICE> <REGISTRY> <AWS_REGION>" >&2
  exit 1
fi

IMAGE="${REGISTRY}/${SERVICE}:latest"
CACHE_DIR="$HOME/.cache/trivy"
REPORT_DIR=".ci_artifacts/${SERVICE}/${GITHUB_SHA}/trivy-scan"
mkdir -p "${CACHE_DIR}" "${REPORT_DIR}"

echo "📦 [Trivy Setup] Using cache directory: ${CACHE_DIR}"
echo "🔍 [Trivy] Scanning image: ${IMAGE}"

# Ensure the latest Trivy DB is downloaded or refreshed
if [ ! -d "${CACHE_DIR}" ]; then
  mkdir -p "${CACHE_DIR}"
fi
trivy --cache-dir "${CACHE_DIR}" image --download-db-only || echo "⚠️ Couldn't refresh DB, using cached one."

# Run Trivy image scan
trivy image \
  --cache-dir "${CACHE_DIR}" \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --format table \
  --output "${REPORT_DIR}/${SERVICE}-image-report.txt" \
  "${IMAGE}" || true

echo "✅ [Trivy] Image scan completed: ${REPORT_DIR}/${SERVICE}-image-report.txt"

# Generate SBOM in CycloneDX format
echo "📦 [SBOM] Generating CycloneDX SBOM..."
trivy image \
  --cache-dir "${CACHE_DIR}" \
  --format cyclonedx \
  --output "${REPORT_DIR}/${SERVICE}-sbom.xml" \
  "${IMAGE}"

echo "✅ [SBOM] Generated at ${REPORT_DIR}/${SERVICE}-sbom.xml"

# Generate scan summary JSON
{
  echo "{"
  echo "  \"service\": \"${SERVICE}\","
  echo "  \"image\": \"${IMAGE}\","
  echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
  echo "  \"region\": \"${AWS_REGION}\""
  echo "}"
} > "${REPORT_DIR}/metadata.json"

# Compress for upload (optional)
tar -czf "${REPORT_DIR}/${SERVICE}-trivy-artifacts.tar.gz" -C "${REPORT_DIR}" .

echo "🗂 All reports stored under: ${REPORT_DIR}"
echo "---------------------------------------------"
ls -lh "${REPORT_DIR}"
echo "---------------------------------------------"