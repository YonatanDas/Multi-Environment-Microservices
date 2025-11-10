#!/bin/bash
set -e

echo "🔧 Setting up Docker Buildx and cache..."

# Setup Buildx
docker buildx create --use || true

# Create local cache directory
mkdir -p /gha/.buildx-cache

echo "✅ Buildx and cache initialized successfully."