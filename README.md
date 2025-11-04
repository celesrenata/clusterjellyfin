# ClusterJellyfin

## Architecture

```
┌─────────────────────────────────────┐
│          Ingress Controller         │
│        (Traefik/NGINX)              │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ Main Jellyfin Pod (Web UI & API)    │
│ ↔ PostgreSQL Database (DB Pod)      │
└─────────────────────────────────────┘
              │
              ▼
┌───────────────────────────────────────────┐
│ Worker Pods (3) - Distributed Transcoders │
└───────────────────────────────────────────┘
```

## Key Features

- ✅ **Ingress Controller**: Dedicated controller for external traffic routing (Traefik/NGINX)
- ✅ **PostgreSQL Database Pod**: Dedicated database pod for production use
- ✅ **Main Jellyfin Pod**: Single pod handling web UI and API orchestration
- ✅ **Distributed Transcoding**: Three worker pods handling all transcoding tasks
- ✅ **Bidirectional Database Connection**: Arrows between Main and DB show bidirectional communication
- ✅ **Scalable Architecture**: Easily add more worker pods as needed

## Installation

Follow the [INSTALL.md](INSTALL.md) guide for detailed setup instructions.

## Documentation

- [COMPREHENSIVE_DOCUMENTATION.md](COMPREHENSIVE_DOCUMENTATION.md)
- [PRODUCTION_EXAMPLE.md](PRODUCTION_EXAMPLE.md)
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
