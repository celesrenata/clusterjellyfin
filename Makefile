# ClusterJellyfin Build Makefile

REGISTRY ?= ghcr.io/celesrenata
TAG ?= sqlmite
DOCKER_DIR = docker

# Image names
JELLYFIN_IMAGE = $(REGISTRY)/clusterjellyfin
WORKER_IMAGE = $(REGISTRY)/clusterjellyfin-worker
IPEX_WORKER_IMAGE = $(REGISTRY)/clusterjellyfin-ipex-worker

.PHONY: all build push clean docker-build docker-push local-push

all: build

# Build all images
build: build-jellyfin build-worker build-ipex-worker

# Build individual images
build-jellyfin:
	@echo "🔨 Building Jellyfin main image..."
	docker build -f $(DOCKER_DIR)/Dockerfile.jellyfin-rffmpeg -t $(JELLYFIN_IMAGE):$(TAG) $(DOCKER_DIR)

build-worker:
	@echo "🔨 Building worker image..."
	docker build -f $(DOCKER_DIR)/Dockerfile.rffmpeg-worker -t $(WORKER_IMAGE):$(TAG) $(DOCKER_DIR)

build-ipex-worker:
	@echo "🔨 Building Intel IPEX worker image..."
	docker build -f $(DOCKER_DIR)/Dockerfile.ipex-worker -t $(IPEX_WORKER_IMAGE):$(TAG) $(DOCKER_DIR)

# Push all images
push: push-jellyfin push-worker push-ipex-worker

push-jellyfin:
	@echo "📤 Pushing Jellyfin main image..."
	docker push $(JELLYFIN_IMAGE):$(TAG)

push-worker:
	@echo "📤 Pushing worker image..."
	docker push $(WORKER_IMAGE):$(TAG)

push-ipex-worker:
	@echo "📤 Pushing Intel IPEX worker image..."
	docker push $(IPEX_WORKER_IMAGE):$(TAG)

# Build and push (standard workflow)
docker-build: build

docker-push: push

# Local registry push (if using local registry)
local-push: build
	@echo "📤 Pushing to local registry..."
	docker tag $(JELLYFIN_IMAGE):$(TAG) registry.celestium.life/clusterjellyfin:$(TAG)
	docker tag $(WORKER_IMAGE):$(TAG) registry.celestium.life/clusterjellyfin-worker:$(TAG)
	docker tag $(IPEX_WORKER_IMAGE):$(TAG) registry.celestium.life/clusterjellyfin-ipex-worker:$(TAG)
	docker push registry.celestium.life/clusterjellyfin:$(TAG)
	docker push registry.celestium.life/clusterjellyfin-worker:$(TAG)
	docker push registry.celestium.life/clusterjellyfin-ipex-worker:$(TAG)

# Clean up local images
clean:
	@echo "🧹 Cleaning up local images..."
	-docker rmi $(JELLYFIN_IMAGE):$(TAG)
	-docker rmi $(WORKER_IMAGE):$(TAG)
	-docker rmi $(IPEX_WORKER_IMAGE):$(TAG)

# Help
help:
	@echo "ClusterJellyfin Build Commands:"
	@echo "  make build          - Build all container images"
	@echo "  make push           - Push all images to registry"
	@echo "  make docker-build   - Build all images (alias for build)"
	@echo "  make docker-push    - Push all images (alias for push)"
	@echo "  make local-push     - Build and push to local registry"
	@echo "  make clean          - Remove local images"
	@echo ""
	@echo "Individual builds:"
	@echo "  make build-jellyfin    - Build main Jellyfin image"
	@echo "  make build-worker      - Build worker image"
	@echo "  make build-ipex-worker - Build Intel IPEX worker image"
	@echo ""
	@echo "Variables:"
	@echo "  REGISTRY=$(REGISTRY)"
	@echo "  TAG=$(TAG)"
