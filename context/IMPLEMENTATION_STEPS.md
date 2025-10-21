l# Implementation Steps: SQLite to PostgreSQL Bridge Integration

## Overview

This document outlines the step-by-step implementation approach for integrating the SQLite to PostgreSQL bridge with Jellyfin, enabling transparent access to PostgreSQL databases while maintaining SQLite interface compatibility.

## Phase 1: Environment Setup

### 1.1 Repository Preparation
```bash
# Ensure we're in the correct repository
cd ~/sources/kube/clusterjellyfin
git checkout clusterjellyfine-sqlmite
git pull origin main

# Verify current status
git status
```

### 1.2 Context Directory Setup
```bash
# Create context directory if it doesn't exist
mkdir -p context
```

## Phase 2: Bridge Integration

### 2.1 Modify Deployment Templates

#### 2.1.1 Update jellyfin-deployment.yaml

Add bridge container to the deployment:

```yaml
# In the containers section of jellyfin-deployment.yaml
containers:
- name: jellyfin
  # ... existing jellyfin container configuration
  
- name: sqlite-postgres-bridge
  image: "{{ .Values.bridge.image.repository }}:{{ .Values.bridge.image.tag }}"
  imagePullPolicy: {{ .Values.bridge.image.pullPolicy }}
  env:
  - name: POSTGRES_HOST
    value: "{{ .Values.postgresql.host }}"
  - name: POSTGRES_PORT
    value: "{{ .Values.postgresql.port | quote }}"
  - name: POSTGRES_DB
    value: "{{ .Values.postgresql.database }}"
  - name: POSTGRES_USER
    value: "{{ .Values.postgresql.username }}"
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: "{{ include "clusterjellyfin.fullname" . }}-postgresql"
        key: postgresql-password
  - name: BRIDGE_POOL_SIZE
    value: "{{ .Values.bridge.connectionPoolSize | quote }}"
  volumeMounts:
  - name: jellyfin-config
    mountPath: /config
  - name: jellyfin-cache
    mountPath: /cache
  - name: jellyfin-media
    mountPath: /media
  # Bridge specific mounts
  - name: bridge-logs
    mountPath: /var/log/bridge
  resources:
    {{- toYaml .Values.bridge.resources | nindent 6 }}
```

### 2.2 Update Values Configuration

#### 2.2.1 Add Bridge Configuration to values.yaml

```yaml
# Bridge configuration
bridge:
  enabled: true
  image:
    repository: "ghcr.io/celesrenata/sqlite-postgres-bridge"
    tag: "latest"
    pullPolicy: IfNotPresent
  connectionPoolSize: 5
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  verbose: false
```

## Phase 3: Configuration Management

### 3.1 Environment Variables Setup

Create proper environment variables for the bridge:
- `POSTGRES_HOST`: PostgreSQL host
- `POSTGRES_PORT`: PostgreSQL port  
- `POSTGRES_DB`: Database name
- `POSTGRES_USER`: Database user
- `POSTGRES_PASSWORD`: Database password
- `BRIDGE_POOL_SIZE`: Connection pool size

### 3.2 Volume Mounts

Ensure proper volume mounts for:
- Configuration storage
- Cache storage  
- Media storage
- Bridge logs

## Phase 4: Testing and Validation

### 4.1 Unit Testing

Test individual bridge components:
```bash
# Run unit tests for bridge components
cd ~/sources/kube/clusterjellyfin
python -m pytest tests/ -v
```

### 4.2 Integration Testing

Test end-to-end functionality:
```bash
# Test bridge integration
cd ~/sources/kube/clusterjellyfin
helm template . --values context/example-values.yaml
```

### 4.3 Performance Testing

Validate performance characteristics:
```bash
# Run performance benchmarks
cd ~/sources/kube/clusterjellyfin
./scripts/performance-test.sh
```

## Phase 5: Deployment

### 5.1 Helm Chart Preparation

```bash
# Package the chart
helm package charts/clusterjellyfin

# Test deployment
helm install jellyfin-test ./clusterjellyfin-*.tgz \
  --namespace jellyfin-system \
  -f context/example-values.yaml
```

### 5.2 Validation

Verify deployment:
```bash
# Check pod status
kubectl get pods -n jellyfin-system

# Check logs
kubectl logs -n jellyfin-system deployment/jellyfin-clusterjellyfin-main

# Validate database connectivity
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- \
  python -c "import sqlite3; conn = sqlite3.connect('/config/jellyfin.db'); print('Connection successful')"
```

## Phase 6: Documentation

### 6.1 Update Documentation

Update the following files:
- `context/INTEGRATION_SUMMARY.md`
- `context/TECHNICAL_APPROACH.md`
- `context/IMPLEMENTATION_STEPS.md`

### 6.2 Deployment Instructions

Create deployment documentation:
```bash
# Deployment checklist
1. Backup existing database
2. Configure PostgreSQL database
3. Deploy bridge integration
4. Test connectivity
5. Monitor performance
6. Validate functionality
```

## Phase 7: Monitoring and Maintenance

### 7.1 Logging Setup

Configure logging for:
- Bridge operations
- Database connectivity
- Performance metrics

### 7.2 Monitoring

Set up monitoring for:
- Resource utilization
- Connection pool usage
- Performance metrics

### 7.3 Maintenance

Regular maintenance tasks:
- Database backups
- Performance tuning
- Security updates
- Monitoring review

## Troubleshooting

### Common Issues

1. **Connection Refused**: Verify PostgreSQL service is running
2. **Authentication Failed**: Check database credentials
3. **Performance Issues**: Review connection pool settings
4. **Deployment Failures**: Check Helm template syntax

### Debugging Commands

```bash
# Debug connection
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- \
  ping postgresql-service

# Check bridge logs
kubectl logs -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -c sqlite-postgres-bridge

# Test database access
kubectl exec -n jellyfin-system deployment/jellyfin-clusterjellyfin-main -- \
  psql -h postgresql-service -U jellyfin -d jellyfin -c "SELECT 1"
