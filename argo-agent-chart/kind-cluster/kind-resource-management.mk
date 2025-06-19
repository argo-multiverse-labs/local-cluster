################################################################################
# KIND Cluster Resource Management                                             #
# Reusable makefile for managing KIND cluster containers on Linux             #
################################################################################

# Default cluster name - can be overridden by including makefile
KIND_CLUSTER_NAME ?= argo-agent-chart

# Colors for output
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
NC=\033[0m

.PHONY: pause-cluster
pause-cluster: ## pause all containers in the KIND cluster to free CPU/memory
	@echo "${YELLOW}Pausing KIND cluster '$(KIND_CLUSTER_NAME)' containers...${NC}"
	@containers=$$(docker ps --filter "label=io.x-k8s.kind.cluster=$(KIND_CLUSTER_NAME)" --format "{{.ID}}"); \
	if [ -z "$$containers" ]; then \
		echo "No KIND cluster containers found to pause."; \
	else \
		echo "Pausing containers: $$containers"; \
		echo $$containers | xargs docker pause; \
		echo "${GREEN}KIND cluster containers paused. Use 'make unpause-cluster' to resume.${NC}"; \
	fi

.PHONY: unpause-cluster
unpause-cluster: ## resume paused KIND cluster containers
	@echo "${YELLOW}Unpausing KIND cluster '$(KIND_CLUSTER_NAME)' containers...${NC}"
	@containers=$$(docker ps --filter "label=io.x-k8s.kind.cluster=$(KIND_CLUSTER_NAME)" --filter "status=paused" --format "{{.ID}}"); \
	if [ -z "$$containers" ]; then \
		echo "No paused KIND cluster containers found."; \
	else \
		echo "Unpausing containers: $$containers"; \
		echo $$containers | xargs docker unpause; \
		echo "${GREEN}KIND cluster containers resumed.${NC}"; \
	fi

.PHONY: stop-cluster
stop-cluster: ## stop KIND cluster containers (preserves state, faster restart than recreating)
	@echo "${YELLOW}Stopping KIND cluster '$(KIND_CLUSTER_NAME)' containers...${NC}"
	@containers=$$(docker ps --filter "label=io.x-k8s.kind.cluster=$(KIND_CLUSTER_NAME)" --format "{{.ID}}"); \
	if [ -z "$$containers" ]; then \
		echo "No running KIND cluster containers found."; \
	else \
		echo "Stopping containers: $$containers"; \
		echo $$containers | xargs docker stop; \
		echo "${GREEN}KIND cluster containers stopped. Use 'make start-cluster' to restart.${NC}"; \
	fi

.PHONY: start-cluster
start-cluster: ## start stopped KIND cluster containers
	@echo "${YELLOW}Starting KIND cluster '$(KIND_CLUSTER_NAME)' containers...${NC}"
	@containers=$$(docker ps -a --filter "label=io.x-k8s.kind.cluster=$(KIND_CLUSTER_NAME)" --filter "status=exited" --format "{{.ID}}"); \
	if [ -z "$$containers" ]; then \
		echo "No stopped KIND cluster containers found."; \
	else \
		echo "Starting containers: $$containers"; \
		echo $$containers | xargs docker start; \
		echo "${GREEN}KIND cluster containers started.${NC}"; \
		echo "Waiting for cluster to be ready..."; \
		kubectl wait --for=condition=Ready nodes --all --timeout=60s --context=kind-$(KIND_CLUSTER_NAME) || true; \
	fi

.PHONY: cluster-status
cluster-status: ## show KIND cluster container status and resource usage
	@echo "${YELLOW}KIND Cluster '$(KIND_CLUSTER_NAME)' Status:${NC}"
	@echo "=========================================="
	@containers=$$(docker ps -a --filter "label=io.x-k8s.kind.cluster=$(KIND_CLUSTER_NAME)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"); \
	if [ -z "$$containers" ]; then \
		echo "No KIND cluster containers found."; \
	else \
		echo "$$containers"; \
	fi
	@echo ""
	@echo "${YELLOW}Resource Usage:${NC}"
	@echo "==============="
	@docker stats --no-stream --filter "label=io.x-k8s.kind.cluster=$(KIND_CLUSTER_NAME)" --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null || echo "No running containers to show stats for."

.PHONY: resource-usage
resource-usage: ## show overall Docker resource usage
	@echo "${YELLOW}Docker System Resource Usage:${NC}"
	@echo "============================="
	@docker system df
	@echo ""
	@echo "${YELLOW}Running Container Stats:${NC}"
	@echo "========================"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null || echo "No running containers."

.PHONY: cleanup-docker
cleanup-docker: ## clean up unused Docker images, containers, and volumes (frees disk space)
	@echo "${YELLOW}Cleaning up unused Docker resources...${NC}"
	@echo "This will remove:"
	@echo "- All stopped containers"
	@echo "- All networks not used by at least one container"
	@echo "- All dangling images"
	@echo "- All dangling build cache"
	@read -p "Continue? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker system prune -f; \
		echo "${GREEN}Docker cleanup completed.${NC}"; \
	else \
		echo "Docker cleanup cancelled."; \
	fi

.PHONY: cleanup-docker-aggressive
cleanup-docker-aggressive: ## aggressive cleanup - removes ALL unused images (not just dangling)
	@echo "${RED}WARNING: This will remove ALL unused Docker images, not just dangling ones!${NC}"
	@echo "This includes images that could be used to recreate containers quickly."
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker system prune -a -f; \
		echo "${GREEN}Aggressive Docker cleanup completed.${NC}"; \
	else \
		echo "Aggressive cleanup cancelled."; \
	fi

.PHONY: sleep-mode
sleep-mode: kill-port-forwards pause-cluster ## put cluster in sleep mode (kill port-forwards and pause containers)
	@echo "${GREEN}KIND cluster '$(KIND_CLUSTER_NAME)' is now in sleep mode.${NC}"
	@echo "- Port forwards killed"
	@echo "- Containers paused (CPU/memory freed)"
	@echo "Use 'make wake-up' to resume."

.PHONY: wake-up
wake-up: unpause-cluster ## wake up cluster from sleep mode
	@echo "${GREEN}KIND cluster '$(KIND_CLUSTER_NAME)' awakened.${NC}"
	@echo "You may want to run 'make all-pf' to restore port forwards."

# Utility targets for monitoring resource usage
.PHONY: watch-resources
watch-resources: ## continuously monitor cluster resource usage (Ctrl+C to stop)
	@echo "${YELLOW}Monitoring KIND cluster '$(KIND_CLUSTER_NAME)' resources (Ctrl+C to stop)...${NC}"
	@while true; do \
		clear; \
		echo "${YELLOW}KIND Cluster '$(KIND_CLUSTER_NAME)' Resource Monitor - $$(date)${NC}"; \
		echo "======================================================="; \
		docker stats --no-stream --filter "label=io.x-k8s.kind.cluster=$(KIND_CLUSTER_NAME)" --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null || echo "No running containers."; \
		sleep 5; \
	done

.PHONY: cluster-logs
cluster-logs: ## show logs from all cluster containers
	@echo "${YELLOW}KIND cluster '$(KIND_CLUSTER_NAME)' container logs:${NC}"
	@containers=$$(docker ps --filter "label=io.x-k8s.kind.cluster=$(KIND_CLUSTER_NAME)" --format "{{.Names}}"); \
	if [ -z "$$containers" ]; then \
		echo "No KIND cluster containers found."; \
	else \
		for container in $$containers; do \
			echo ""; \
			echo "${YELLOW}=== Logs for $$container ===${NC}"; \
			docker logs --tail=50 $$container; \
		done; \
	fi