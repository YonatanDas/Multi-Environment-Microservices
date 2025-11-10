#!/bin/bash
set -e

echo "🧹 Cleaning up Docker build cache..."
rm -rf /tmp/.buildx-cache
mv /tmp/.buildx-cache-new /tmp/.buildx-cache
echo "✅ Docker cache updated."