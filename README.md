# ClusterJellyfin

Kubernetes-deployed Jellyfin media server with distributed transcoding using rffmpeg to load-balance Intel Arc QSV hardware acceleration across multiple worker nodes for scalable performance.

## Features

- **Distributed Transcoding**: Uses rffmpeg to distribute transcoding workload across multiple worker nodes
- **Intel Arc QSV Acceleration**: Hardware-accelerated transcoding on Intel Arc GPUs
- **Scalable Architecture**: Main Jellyfin instance handles UI/API, workers handle transcoding
- **Helm Chart**: Easy deployment and configuration via Helm
- **Container Images**: Pre-built Docker images available on GitHub Container Registry

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Jellyfin      │    │   rffmpeg       │
│   Main          │───▶│   Worker 1      │
│   (UI/API)      │    │   (Intel Arc)   │
└─────────────────┘    └─────────────────┘
                       ┌─────────────────┐
                       │   rffmpeg       │
                       │   Worker 2      │
                       │   (Intel Arc)   │
                       └─────────────────┘
                       ┌─────────────────┐
                       │   rffmpeg       │
                       │   Worker 3      │
                       │   (Intel Arc)   │
                       └─────────────────┘
```

## Prerequisites

- Kubernetes cluster with nodes that have Intel Arc GPUs
- Intel GPU device plugin installed
- Helm 3.x
- Storage classes for persistent volumes

## Quick Start

1. **Add the Helm repository**:
   ```bash
   helm repo add clusterjellyfin https://celesrenata.github.io/clusterjellyfin
   helm repo update
   ```

2. **Install ClusterJellyfin**:
   ```bash
   helm install jellyfin clusterjellyfin/clusterjellyfin \
     --create-namespace \
     --namespace jellyfin \
     --set workers.nodeSelector.nodes[0]=node-with-arc-gpu-1 \
     --set workers.nodeSelector.nodes[1]=node-with-arc-gpu-2
   ```

3. **Access Jellyfin**:
   ```bash
   kubectl port-forward -n jellyfin svc/jellyfin-main 8096:8096
   ```
   Open http://localhost:8096

## Configuration

### Basic Configuration

```yaml
# values.yaml
workers:
  replicas: 3
  nodeSelector:
    nodes:
      - gpu-node-1
      - gpu-node-2
      - gpu-node-3

jellyfin:
  storage:
    media:
      size: 2Ti
      storageClass: "fast-ssd"
```

### Advanced Configuration

See [values.yaml](charts/clusterjellyfin/values.yaml) for all available options.

## Storage Requirements

- **Config**: 10Gi (Jellyfin configuration and metadata)
- **Cache**: 50Gi (Transcoding cache)
- **Media**: Variable (Your media library)

## GPU Requirements

Each worker node should have:
- Intel Arc GPU (A380, A750, A770, etc.)
- Intel GPU device plugin installed
- Proper drivers and runtime

## Development

### Building Images Locally

```bash
# Build main image
docker build -f docker/Dockerfile.jellyfin-rffmpeg -t clusterjellyfin-main docker/

# Build worker image  
docker build -f docker/Dockerfile.rffmpeg-worker -t clusterjellyfin-worker docker/
```

### Testing Helm Chart

```bash
helm template jellyfin charts/clusterjellyfin --values charts/clusterjellyfin/values.yaml
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with your Kubernetes cluster
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Jellyfin](https://jellyfin.org/) - The media server
- [rffmpeg](https://github.com/joshuaboniface/rffmpeg) - Remote FFmpeg execution
- Intel Arc GPU support in FFmpeg
