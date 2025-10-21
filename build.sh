#!/usr/bin/env bash
set -e

# Configuration
TAG=${TAG:-sqlmite}
REGISTRY=${REGISTRY:-ghcr.io/celesrenata}

echo "🔨 Building ClusterJellyfin containers (tag: $TAG)..."

# Build all images
echo "📦 Building main Jellyfin image..."
make build-jellyfin TAG=$TAG REGISTRY=$REGISTRY

echo "📦 Building worker image..."
make build-worker TAG=$TAG REGISTRY=$REGISTRY

echo "📦 Building Intel IPEX worker image..."
make build-ipex-worker TAG=$TAG REGISTRY=$REGISTRY

echo "✅ All images built successfully!"
echo ""
echo "🚀 Next steps:"
echo "   make docker-push TAG=$TAG    # Push to registry"
echo "   ./runmefirst.sh              # Deploy to cluster"
