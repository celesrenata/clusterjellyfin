# ClusterJellyfin

Distributed Jellyfin deployment with remote transcoding workers using rffmpeg.

## Features

- **Distributed Transcoding**: Main Jellyfin instance delegates transcoding to worker pods via SSH
- **Hardware Acceleration**: Workers support Intel QSV, NVIDIA CUDA, AMD VAAPI
- **Auto-scaling**: StatefulSet workers with configurable replica count
- **Load Balancing**: Automatic distribution of transcoding jobs across available workers
- **Persistent Storage**: NFS and Longhorn support for media, config, and cache

## Architecture

```
┌─────────────────┐    SSH/rffmpeg    ┌─────────────────┐
│   Jellyfin      │ ─────────────────▶ │   Worker Pods   │
│   Main Pod      │                   │                 │
│   (Web UI)      │                   │   FFmpeg +      │
└─────────────────┘                   │   HW Accel      │
                                      └─────────────────┘
```

## Quick Start

### Prerequisites

- Kubernetes cluster
- Helm 3.x
- NFS server (optional, for shared storage)

### Installation

1. **Add the Helm repository:**
   ```bash
   helm repo add clusterjellyfin https://celesrenata.github.io/clusterjellyfin
   helm repo update
   ```

2. **Install ClusterJellyfin:**
   ```bash
   helm install jellyfin clusterjellyfin/clusterjellyfin \
     --namespace jellyfin-system \
     --create-namespace \
     --set workers.gpu.enabled=false \
     --set workers.privileged=true \
     --set service.type=ClusterIP
   ```

3. **Access Jellyfin:**
   ```bash
   kubectl port-forward -n jellyfin-system svc/jellyfin-clusterjellyfin-main 8096:8096
   ```
   Open http://localhost:8096

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `workers.replicas` | Number of transcoding workers | `3` |
| `workers.privileged` | Enable privileged mode for GPU access | `false` |
| `workers.gpu.enabled` | Enable GPU support | `false` |
| `service.type` | Service type (ClusterIP/LoadBalancer/NodePort) | `ClusterIP` |

### Storage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `storage.config.storageClass` | Storage class for config | `""` (NFS) |
| `storage.config.size` | Config storage size | `10Gi` |
| `storage.media.storageClass` | Storage class for media | `""` (NFS) |
| `storage.media.size` | Media storage size | `1Ti` |
| `storage.cache.storageClass` | Storage class for cache | `longhorn` |
| `storage.cache.size` | Cache storage size | `50Gi` |

### GPU Support

For NVIDIA GPU support:
```bash
helm install jellyfin clusterjellyfin/clusterjellyfin \
  --set workers.gpu.enabled=true \
  --set workers.privileged=true \
  --set workers.resources.limits."nvidia\.com/gpu"=1
```

For Intel GPU support:
```bash
helm install jellyfin clusterjellyfin/clusterjellyfin \
  --set workers.privileged=true \
  --set workers.resources.limits."gpu\.intel\.com/i915"=1
```

## Advanced Configuration

### Custom Values File

Create `values.yaml`:
```yaml
workers:
  replicas: 5
  privileged: true
  gpu:
    enabled: true
  resources:
    limits:
      nvidia.com/gpu: 1
    requests:
      cpu: 1000m
      memory: 2Gi

storage:
  config:
    storageClass: "longhorn"
  media:
    storageClass: "nfs-client"
    size: "5Ti"

service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/address-pool: default
```

Install with custom values:
```bash
helm install jellyfin clusterjellyfin/clusterjellyfin \
  --namespace jellyfin-system \
  --create-namespace \
  -f values.yaml
```

### NFS Storage Setup

For NFS storage, ensure your cluster has NFS support and update the PV configuration:
```yaml
nfs:
  server: "192.168.1.100"
  configPath: "/mnt/jellyfin/config"
  mediaPath: "/mnt/jellyfin/media"
```

## Distributed Transcoding

ClusterJellyfin uses rffmpeg to distribute transcoding jobs:

1. **Validation calls** (`-version`, `-codecs`, etc.) run locally on main pod
2. **Transcoding jobs** are distributed to worker pods via SSH
3. **Load balancing** automatically spreads jobs across available workers
4. **Hardware acceleration** is available on worker pods

### Monitoring Transcoding

Check worker pod logs:
```bash
kubectl logs -n jellyfin-system jellyfin-clusterjellyfin-workers-0
```

Test distributed transcoding:
```bash
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- \
  /usr/local/bin/rffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=1 -c:v libx264 -f null -
```

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n jellyfin-system
```

### Check SSH Connectivity
```bash
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- \
  ssh -o StrictHostKeyChecking=no -i /home/jellyfin/.ssh/id_rsa \
  jellyfin@jellyfin-clusterjellyfin-workers "echo 'SSH works'"
```

### Check Storage
```bash
kubectl get pv,pvc -n jellyfin-system
```

### View Logs
```bash
# Main pod logs
kubectl logs -n jellyfin-system deployment/jellyfin-clusterjellyfin-main

# Worker pod logs
kubectl logs -n jellyfin-system jellyfin-clusterjellyfin-workers-0
```

## Upgrading

```bash
helm repo update
helm upgrade jellyfin clusterjellyfin/clusterjellyfin --namespace jellyfin-system
```

## Uninstalling

```bash
helm uninstall jellyfin --namespace jellyfin-system
kubectl delete namespace jellyfin-system
```

## Development

### Building from Source

```bash
git clone https://github.com/celesrenata/clusterjellyfin
cd clusterjellyfin
helm package charts/clusterjellyfin
helm install jellyfin ./clusterjellyfin-*.tgz --namespace jellyfin-system --create-namespace
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [Jellyfin](https://jellyfin.org/) - The media server
- [rffmpeg](https://github.com/joshuaboniface/rffmpeg) - Remote FFmpeg execution
- [Kubernetes](https://kubernetes.io/) - Container orchestration
- [Helm](https://helm.sh/) - Package manager for Kubernetes
