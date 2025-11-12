#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./04b-scan-jar-before-push.sh <SERVICE>
#
# Example:
#   ./04b-scan-jar-before-push.sh gateway

SERVICE="${1:-}"
if [[ -z "$SERVICE" ]]; then
  echo "❌ Usage: $0 <SERVICE>" >&2
  exit 1
fi

JAR_PATH=".ci_artifacts/${SERVICE}/${GITHUB_SHA}/build/jar-files"
REPORT_DIR=".ci_artifacts/${SERVICE}/${GITHUB_SHA}/prepush-scan"
mkdir -p "${REPORT_DIR}"

if ! command -v trivy &>/dev/null; then
  echo "Installing Trivy..."
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh
fi

echo "🔍 Scanning extracted JARs with Trivy..."
for jar in "${JAR_PATH}"/*.jar; do
  trivy fs 
  --severity HIGH,CRITICAL
 --ignore-unfixed \
    --format table \
     --output "${REPORT_DIR}/$(basename "$jar")-scan.txt" "$jar" || true
done

echo "✅ Pre-push JAR vulnerability scan complete."