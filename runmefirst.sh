#!/usr/bin/env bash
set -e

# Configuration
TAG=${TAG:-sqlmite}
VALUES_FILE=${VALUES_FILE:-personal-values.yaml}

echo "🚀 Deploying ClusterJellyfin (tag: $TAG)..."

# Check if using custom values file
if [[ -f "$VALUES_FILE" ]]; then
    echo "📋 Using values file: $VALUES_FILE"
    VALUES_ARGS="-f $VALUES_FILE"
else
    echo "⚠️  Values file $VALUES_FILE not found, using defaults"
    VALUES_ARGS=""
fi

# Add helm repo if not exists
if ! helm repo list | grep -q clusterjellyfin; then
    echo "📦 Adding ClusterJellyfin Helm repository..."
    helm repo add clusterjellyfin https://celesrenata.github.io/clusterjellyfin
fi

# Update repo
echo "🔄 Updating Helm repositories..."
helm repo update

# Deploy ClusterJellyfin with custom tag
echo "🎬 Installing ClusterJellyfin..."
helm install jellyfin clusterjellyfin/clusterjellyfin \
  --namespace jellyfin-system \
  --create-namespace \
  --set image.tag=$TAG \
  --set workers.image.tag=$TAG \
  --set workers.gpu.enabled=false \
  --set workers.privileged=true \
  --set service.type=ClusterIP \
  $VALUES_ARGS

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
