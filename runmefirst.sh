#!/usr/bin/env bash
set -e

echo "🚀 Deploying ClusterJellyfin..."

# Add helm repo if not exists
if ! helm repo list | grep -q clusterjellyfin; then
    echo "📦 Adding ClusterJellyfin Helm repository..."
    helm repo add clusterjellyfin https://celesrenata.github.io/clusterjellyfin
fi

# Update repo
echo "🔄 Updating Helm repositories..."
helm repo update

# Deploy ClusterJellyfin
echo "🎬 Installing ClusterJellyfin..."
helm install jellyfin clusterjellyfin/clusterjellyfin \
  --namespace jellyfin-system \
  --create-namespace \
  --set workers.gpu.enabled=false \
  --set workers.privileged=true \
  --set service.type=ClusterIP

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=clusterjellyfin -n jellyfin-system --timeout=300s

echo "✅ ClusterJellyfin deployed successfully!"
echo ""
echo "🌐 Access Jellyfin:"
echo "   kubectl port-forward -n jellyfin-system svc/jellyfin-clusterjellyfin-main 8096:8096"
echo "   Then open: http://localhost:8096"
echo ""
echo "🔧 Check status:"
echo "   kubectl get pods -n jellyfin-system"
