# Production Example Configuration

## Complete Production Setup

This example demonstrates a production-ready ClusterJellyfin deployment with:
- External PostgreSQL database
- Intel Arc Graphics acceleration
- NFS media storage
- Ingress with TLS
- Resource optimization

### 1. Prerequisites Setup

**Create namespace:**
```bash
kubectl create namespace jellyfin-system
```

**Create PostgreSQL secret:**
```bash
kubectl create secret generic jellyfin-postgresql-external \
  --from-literal=host="postgres.example.com" \
  --from-literal=port="5432" \
  --from-literal=database="clusterjellyfin" \
  --from-literal=username="jellyfin" \
  --from-literal=password="your-secure-password" \
  -n jellyfin-system
```

### 2. Production values.yaml

```yaml
# Production ClusterJellyfin Configuration
image:
  jellyfin:
    repository: ghcr.io/celesrenata/clusterjellyfin-main
    tag: latest
    pullPolicy: IfNotPresent
  worker:
    repository: ghcr.io/celesrenata/clusterjellyfin-worker
    tag: latest
    pullPolicy: IfNotPresent

# Main Jellyfin configuration
jellyfin:
  replicas: 1
  publishedServerUrl: "https://jellyfin.yourdomain.com"
  
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  storage:
    config:
      size: 10Gi
      storageClass: "longhorn"
      accessMode: ReadWriteOnce
    
    cache:
      size: 100Gi
      storageClass: "longhorn"  # Fast SSD storage
      accessMode: ReadWriteMany
    
    media:
      size: 10Ti
      storageClass: ""
      nfs:
        server: "192.168.1.100"
        path: "/mnt/media"

# External PostgreSQL configuration
postgresql:
  enabled: false
  external:
    host: "postgres.example.com"
    port: 5432
    database: "clusterjellyfin"
    username: "jellyfin"
    existingSecret: "jellyfin-postgresql-external"

# Worker configuration with Intel Arc Graphics
workers:
  replicas: 4
  privileged: true
  
  resources:
    requests:
      cpu: 2000m
      memory: 4Gi
    limits:
      cpu: 4000m
      memory: 8Gi
  
  # Target specific GPU nodes
  nodeSelector:
    enabled: true
    nodes:
      - gpu-worker-1
      - gpu-worker-2
      - gpu-worker-3
      - gpu-worker-4
  
  # Intel Arc Graphics acceleration
  gpu:
    enabled: true
    resource: "gpu.intel.com/i915"
    limit: 1

# Service configuration
service:
  type: ClusterIP
  port: 8096
  httpsPort: 8920

# Ingress with TLS
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
  hosts:
    - host: jellyfin.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: jellyfin-tls
      hosts:
        - jellyfin.yourdomain.com

# Security context
securityContext:
  runAsUser: 1001
  runAsGroup: 1001
  fsGroup: 1001
```

### 3. Installation Commands

```bash
# Add Helm repository
helm repo add clusterjellyfin https://celesrenata.github.io/clusterjellyfin
helm repo update

# Install with production configuration
helm install jellyfin clusterjellyfin/clusterjellyfin \
  --namespace jellyfin-system \
  --create-namespace \
  -f production-values.yaml

# Verify installation
kubectl get pods -n jellyfin-system -w
```

### 4. Post-Installation Verification

**Check pod status:**
```bash
kubectl get pods -n jellyfin-system
```

Expected output:
```
NAME                                             READY   STATUS    RESTARTS   AGE
jellyfin-clusterjellyfin-main-xxx                1/1     Running   2          5m
jellyfin-clusterjellyfin-workers-0               1/1     Running   0          5m
jellyfin-clusterjellyfin-workers-1               1/1     Running   0          5m
jellyfin-clusterjellyfin-workers-2               1/1     Running   0          5m
jellyfin-clusterjellyfin-workers-3               1/1     Running   0          5m
```

**Test distributed transcoding:**
```bash
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- \
  /shared/rffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=1 \
  -c:v libx264 -f null -
```

**Verify GPU access:**
```bash
kubectl exec -n jellyfin-system jellyfin-clusterjellyfin-workers-0 -- \
  ls -la /dev/dri/
```

**Check PostgreSQL connection:**
```bash
kubectl logs -n jellyfin-system -l component=main | grep -i postgres
```

### 5. Access Jellyfin

**Via Ingress (Production):**
- Open https://jellyfin.yourdomain.com
- Complete initial setup wizard

**Via Port Forward (Testing):**
```bash
kubectl port-forward -n jellyfin-system svc/jellyfin-clusterjellyfin-main 8096:8096
```
- Open http://localhost:8096

### 6. Initial Configuration

1. **Complete Setup Wizard:**
   - Set admin username/password
   - Add media libraries pointing to `/media`
   - Configure transcoding settings

2. **Enable Hardware Acceleration:**
   - Dashboard → Playback → Transcoding
   - Hardware acceleration: Intel QuickSync (QSV)
   - Enable hardware decoding for all codecs

3. **Verify Distributed Transcoding:**
   - Start playing a video that requires transcoding
   - Check worker logs: `kubectl logs -n jellyfin-system jellyfin-clusterjellyfin-workers-0 -f`
   - Monitor cache: `kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- ls -la /cache/transcodes/`

## Alternative Configurations

### NVIDIA GPU Configuration

```yaml
workers:
  replicas: 2
  privileged: true
  gpu:
    enabled: true
    resource: "nvidia.com/gpu"
    limit: 1
  resources:
    limits:
      nvidia.com/gpu: 1
```

### LoadBalancer Service (No Ingress)

```yaml
service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/address-pool: default
    metallb.universe.tf/allow-shared-ip: jellyfin
```

### All Dynamic Storage

```yaml
jellyfin:
  storage:
    config:
      storageClass: "longhorn"
    cache:
      storageClass: "longhorn"
    media:
      storageClass: "nfs-client"
```

### High-Performance Configuration

```yaml
jellyfin:
  resources:
    requests:
      cpu: 2000m
      memory: 4Gi
    limits:
      cpu: 4000m
      memory: 8Gi

workers:
  replicas: 6
  resources:
    requests:
      cpu: 4000m
      memory: 8Gi
    limits:
      cpu: 8000m
      memory: 16Gi
```

## Monitoring and Maintenance

### Health Checks

```bash
# Check all components
kubectl get all -n jellyfin-system

# Verify storage
kubectl get pv,pvc -n jellyfin-system

# Check ingress
kubectl get ingress -n jellyfin-system
```

### Log Monitoring

```bash
# Main pod logs
kubectl logs -n jellyfin-system -l component=main --tail=100 -f

# Worker logs
kubectl logs -n jellyfin-system jellyfin-clusterjellyfin-workers-0 --tail=100 -f

# Filter transcoding activity
kubectl logs -n jellyfin-system -l component=main | grep -E "FFmpeg|transcode"
```

### Performance Monitoring

```bash
# Resource usage
kubectl top pods -n jellyfin-system

# Storage usage
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- df -h

# Active transcoding sessions
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- \
  ls -la /cache/transcodes/
```

This production configuration provides a robust, scalable Jellyfin deployment with distributed transcoding and hardware acceleration capabilities.
