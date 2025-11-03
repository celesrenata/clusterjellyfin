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

# Clean up any existing failed installation
if helm list -n jellyfin-system | grep -q jellyfin; then
    echo "🧹 Cleaning up existing installation..."
    helm uninstall jellyfin -n jellyfin-system || true
    sleep 5
fi

# Create external PostgreSQL secret
echo "🔐 Creating PostgreSQL secret..."
kubectl apply -f postgresql-secret.yaml

# Deploy ClusterJellyfin
echo "🎬 Installing ClusterJellyfin..."
helm install jellyfin clusterjellyfin/clusterjellyfin \
  --namespace jellyfin-system \
  --create-namespace \
  -f personal-values.yaml

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=clusterjellyfin -n jellyfin-system --timeout=300s

echo "🌐 Deploying ingress..."
kubectl apply -f jellyfin-ingress.yaml

echo "✅ ClusterJellyfin deployed successfully!"
echo ""
echo "🌐 Access Jellyfin:"
echo "   https://jellyfin.celestium.life"
echo "   Or port-forward: kubectl port-forward -n jellyfin-system svc/jellyfin-clusterjellyfin-main 8096:8096"
echo ""
echo "🔧 Check status:"
echo "   kubectl get pods -n jellyfin-system"
