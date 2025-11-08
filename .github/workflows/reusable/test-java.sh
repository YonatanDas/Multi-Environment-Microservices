#!/usr/bin/env bash
set -e  # Exit immediately on error

SERVICE_DIR=$1

echo "🔍 Running lint and unit tests in $SERVICE_DIR..."

cd "$SERVICE_DIR"

# Run Checkstyle
mvn -B checkstyle:check

# Run Unit Tests
mvn -B test

# Generate Code Coverage Report
mvn jacoco:report

echo "✅ Lint, tests, and coverage completed for $SERVICE_DIR"