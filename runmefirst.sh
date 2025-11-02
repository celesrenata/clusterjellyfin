#!/usr/bin/env bash
set -e

echo "🚀 Deploying ClusterJellyfin..."

# Check if example-values.yaml exists
if [ ! -f "example-values.yaml" ]; then
    echo "❌ Error: example-values.yaml not found!"
    echo "Please copy and configure example-values.yaml with your settings."
    exit 1
fi

# Deploy ClusterJellyfin from local chart
echo "🎬 Installing ClusterJellyfin from local chart..."
helm upgrade --install jellyfin ./charts/clusterjellyfin \
  --namespace jellyfin-system \
  --create-namespace \
  -f example-values.yaml

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=clusterjellyfin -n jellyfin-system --timeout=300s || true

echo "✅ ClusterJellyfin deployed successfully!"
echo ""
echo "📊 Deployment Info:"
echo "   Image: ghcr.io/celesrenata/clusterjellyfin:main"
echo "   Base: ghcr.io/celesrenata/jellyfin:postgresql"
echo ""
echo "🌐 Access Jellyfin:"
echo "   kubectl port-forward -n jellyfin-system svc/jellyfin-clusterjellyfin 8096:8096"
echo "   Then open: http://localhost:8096"
echo ""
echo "🔧 Check status:"
echo "   kubectl get pods -n jellyfin-system"
echo "   kubectl logs -n jellyfin-system -l app.kubernetes.io/name=clusterjellyfin"
