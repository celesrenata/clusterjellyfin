# ClusterJellyfin

Distributed Jellyfin deployment with remote transcoding workers using rffmpeg. Validated with Intel Arc Graphics hardware acceleration.

## Features

- **PostgreSQL Support**: Uses PostgreSQL-enabled Jellyfin with optional self-hosted or external database
- **Distributed Transcoding**: Main Jellyfin instance delegates transcoding to worker pods via SSH
- **Hardware Acceleration**: Workers support Intel Arc Graphics, NVIDIA CUDA, AMD VAAPI
- **Auto-scaling**: StatefulSet workers with configurable replica count
- **Load Balancing**: Automatic distribution of transcoding jobs across available workers
- **Persistent Storage**: NFS and Longhorn support for media, config, and cache
- **Generic Configuration**: No hardcoded values - fully customizable for any environment

## Architecture

```
┌─────────────────┐    SSH/rffmpeg    ┌─────────────────┐
│   Jellyfin      │ ────────────────▶ │   Worker Pods   │
│   Main Pod      │                   │                 │
│   (Web UI)      │                   │   FFmpeg +      │
└─────────────────┘                   │   HW Accel      │
                                      └─────────────────┘
```

## Quick Start

### Prerequisites

- Kubernetes cluster
- Helm 3.x
- Storage solution (NFS server or dynamic provisioning)

### Container Images

The deployment uses these pre-built container images from GitHub Container Registry:

- **Jellyfin (PostgreSQL)**: `ghcr.io/celesrenata/jellyfin:postgresql`
  - PostgreSQL-enabled Jellyfin with rffmpeg support
  - Built automatically on push to main branch
  
- **Worker**: `ghcr.io/celesrenata/clusterjellyfin-worker:latest`
  - Transcoding worker with hardware acceleration support
  - Built automatically on push to main branch

### Installation

1. **Add the Helm repository:**
   ```bash
   helm repo add clusterjellyfin https://celesrenata.github.io/clusterjellyfin
   helm repo update
   ```

2. **Create your values file:**
   ```bash
   # Download example configuration
   curl -O https://raw.githubusercontent.com/celesrenata/clusterjellyfin/main/example-values.yaml
   
   # Edit with your settings
   cp example-values.yaml values.yaml
   # Configure storage, domains, GPU settings, etc.
   ```

3. **Install ClusterJellyfin:**
   ```bash
   helm install jellyfin clusterjellyfin/clusterjellyfin \
     --namespace jellyfin-system \
     --create-namespace \
     -f values.yaml
   ```

4. **Access Jellyfin:**
   ```bash
   kubectl port-forward -n jellyfin-system svc/jellyfin-clusterjellyfin-main 8096:8096
   ```
   Open http://localhost:8096

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.jellyfin.repository` | Jellyfin container image | `ghcr.io/celesrenata/jellyfin` |
| `image.jellyfin.tag` | Jellyfin image tag | `postgresql` |
| `workers.replicas` | Number of transcoding workers | `3` |
| `workers.privileged` | Enable privileged mode for GPU access | `true` |
| `workers.gpu.enabled` | Enable GPU support | `false` |
| `service.type` | Service type (ClusterIP/LoadBalancer/NodePort) | `ClusterIP` |

### PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Deploy PostgreSQL in cluster | `true` |
| `postgresql.deployment.storage.size` | PostgreSQL storage size | `50Gi` |
| `postgresql.deployment.storage.storageClass` | Storage class for PostgreSQL | `longhorn` |
| `postgresql.external.host` | External PostgreSQL host (when enabled: false) | `""` |
| `postgresql.external.existingSecret` | Secret name for external DB credentials | `jellyfin-postgresql-external` |

### Storage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `jellyfin.storage.config.storageClass` | Storage class for config | `""` |
| `jellyfin.storage.config.size` | Config storage size | `10Gi` |
| `jellyfin.storage.media.storageClass` | Storage class for media | `""` |
| `jellyfin.storage.media.size` | Media storage size | `1Ti` |
| `jellyfin.storage.cache.storageClass` | Storage class for cache | `longhorn` |
| `jellyfin.storage.cache.size` | Cache storage size | `50Gi` |

### PostgreSQL Database

**Self-Hosted PostgreSQL (Default):**
```yaml
postgresql:
  enabled: true
  deployment:
    storage:
      size: 50Gi
      storageClass: "longhorn"
```

**External PostgreSQL:**
```yaml
postgresql:
  enabled: false
  external:
    host: "postgres.example.com"
    port: 5432
    database: "jellyfin"
    username: "jellyfin"
    existingSecret: "jellyfin-postgresql-external"
```

Before deploying with external PostgreSQL, create the secret:
```bash
kubectl create secret generic jellyfin-postgresql-external \
  --namespace jellyfin-system \
  --from-literal=host=postgres.example.com \
  --from-literal=port=5432 \
  --from-literal=database=jellyfin \
  --from-literal=username=jellyfin \
  --from-literal=password=your-secure-password
```

### Hardware Acceleration

**Intel Arc Graphics:**
```yaml
workers:
  privileged: true
  gpu:
    enabled: true
    resource: "gpu.intel.com/i915"
    limit: 1
```

**NVIDIA GPU:**
```yaml
workers:
  privileged: true
  gpu:
    enabled: true
    resource: "nvidia.com/gpu"
    limit: 1
```

## Example Configurations

### Minimal Setup (No GPU)
```yaml
workers:
  replicas: 2
  privileged: true
  gpu:
    enabled: false

jellyfin:
  storage:
    config:
      storageClass: "longhorn"
    media:
      storageClass: "nfs-client"

service:
  type: LoadBalancer
```

### Intel Arc Graphics with PostgreSQL Setup
```yaml
# Use PostgreSQL-enabled Jellyfin image
image:
  jellyfin:
    repository: ghcr.io/celesrenata/jellyfin
    tag: postgresql

# Deploy PostgreSQL in cluster
postgresql:
  enabled: true
  deployment:
    storage:
      size: 50Gi
      storageClass: "longhorn"

workers:
  replicas: 3
  privileged: true
  nodeSelector:
    enabled: true
    nodes:
      - gpu-node-1
      - gpu-node-2
  gpu:
    enabled: true
    resource: "gpu.intel.com/i915"
    limit: 1

jellyfin:
  publishedServerUrl: "https://jellyfin.yourdomain.com"
  storage:
    config:
      storageClass: "longhorn"
    cache:
      storageClass: "longhorn"  # Fast storage for transcoding
    media:
      storageClass: ""
      nfs:
        server: "192.168.1.100"
        path: "/mnt/media"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: jellyfin.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
```

## Distributed Transcoding

ClusterJellyfin uses rffmpeg to distribute transcoding jobs:

1. **Validation calls** (`-version`, `-codecs`, etc.) run locally on main pod
2. **Transcoding jobs** are distributed to worker pods via SSH
3. **Load balancing** automatically spreads jobs across available workers
4. **Hardware acceleration** is available on worker pods
5. **Shared cache** allows workers to write HLS segments accessible by main pod

### Monitoring Transcoding

**Check transcoding activity:**
```bash
# View cache directory for active transcoding
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- ls -la /cache/transcodes/

# Monitor worker logs
kubectl logs -n jellyfin-system jellyfin-clusterjellyfin-workers-0 -f

# Test distributed transcoding
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- \
  /usr/local/bin/rffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=1 -c:v libx264 -f null -
```

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n jellyfin-system
```

### Verify SSH Connectivity
```bash
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- \
  ssh -o StrictHostKeyChecking=no -i /home/jellyfin/.ssh/id_rsa \
  jellyfin@jellyfin-clusterjellyfin-workers "echo 'SSH works'"
```

### Check Storage Mounts
```bash
kubectl get pv,pvc -n jellyfin-system
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- df -h
```

### View Logs
```bash
# Main pod logs
kubectl logs -n jellyfin-system deployment/jellyfin-clusterjellyfin-main

# Worker pod logs
kubectl logs -n jellyfin-system jellyfin-clusterjellyfin-workers-0

# Filter transcoding errors
kubectl logs -n jellyfin-system deployment/jellyfin-clusterjellyfin-main | grep -E "FFmpeg|transcode"
```

### Common Issues

**Transcoding fails with "No such file or directory":**
- Check that workers have access to cache volume: `/cache/transcodes/`
- Verify media volume is mounted on workers: `/media/`

**SSH connection refused:**
- Check worker pods are running: `kubectl get pods -n jellyfin-system`
- Verify SSH keys are generated: `kubectl get secret -n jellyfin-system`
- SSH uses hardcoded 'jellyfin' user - no configuration needed

**GPU not detected:**
- Ensure `privileged: true` is set for workers
- Check GPU resources are available: `kubectl describe node <gpu-node>`
- Verify GPU drivers are installed on nodes

**PostgreSQL connection issues:**
- Check PostgreSQL pod is running: `kubectl get pods -n jellyfin-system -l component=postgresql`
- View PostgreSQL logs: `kubectl logs -n jellyfin-system <postgresql-pod-name>`
- Verify secret exists: `kubectl get secret -n jellyfin-system`
- For external DB, ensure the external secret is created with all required keys (host, port, database, username, password)

## Upgrading

```bash
helm repo update
helm upgrade jellyfin clusterjellyfin/clusterjellyfin \
  --namespace jellyfin-system \
  -f values.yaml
```

## Uninstalling

```bash
helm uninstall jellyfin --namespace jellyfin-system
kubectl delete namespace jellyfin-system
```

## Development

### Building from Source

**Build Helm Chart:**
```bash
git clone https://github.com/celesrenata/clusterjellyfin
cd clusterjellyfin
helm package charts/clusterjellyfin
helm install jellyfin ./clusterjellyfin-*.tgz \
  --namespace jellyfin-system \
  --create-namespace \
  -f values.yaml
```

**Build Container Images:**

The repository includes GitHub Actions workflows that automatically build and push images:

1. **PostgreSQL Jellyfin Image** (`.github/workflows/jellyfin-postgresql-build.yml`)
   - Triggers on changes to `docker/Dockerfile.jellyfin-postgresql`
   - Pushes to `ghcr.io/celesrenata/jellyfin:postgresql`
   - Can be triggered manually via GitHub Actions

2. **Worker Images** (`.github/workflows/docker-build.yml`)
   - Triggers on push to main branch
   - Builds both main and worker images
   - Pushes to `ghcr.io/celesrenata/clusterjellyfin-main` and `ghcr.io/celesrenata/clusterjellyfin-worker`

**Manual Docker Build:**
```bash
# Build PostgreSQL Jellyfin image
docker build -f docker/Dockerfile.jellyfin-postgresql -t ghcr.io/celesrenata/jellyfin:postgresql ./docker

# Build worker image
docker build -f docker/Dockerfile.rffmpeg-worker -t ghcr.io/celesrenata/clusterjellyfin-worker:latest ./docker

# Push to registry (requires authentication)
docker push ghcr.io/celesrenata/jellyfin:postgresql
docker push ghcr.io/celesrenata/clusterjellyfin-worker:latest
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## Validation Status

- **PostgreSQL Integration**: Tested with self-hosted and external PostgreSQL databases
- **Distributed Transcoding**: Tested with multiple concurrent streams
- **Intel Arc Graphics**: Hardware acceleration confirmed working
- **Load Balancing**: Multiple workers processing jobs simultaneously
- **Cache Sharing**: Workers successfully writing to shared cache volume
- **SSH Connectivity**: Automatic key generation and distribution working

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [Jellyfin](https://jellyfin.org/) - The media server
- [rffmpeg](https://github.com/joshuaboniface/rffmpeg) - Remote FFmpeg execution
- [Kubernetes](https://kubernetes.io/) - Container orchestration
- [Helm](https://helm.sh/) - Package manager for Kubernetes
