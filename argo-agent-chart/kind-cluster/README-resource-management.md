# KIND Cluster Resource Management

This directory contains a reusable makefile (`kind-resource-management.mk`) for managing KIND cluster resources on Linux systems. This solves the resource management challenges when moving from macOS Docker Desktop (with VM isolation) to native Linux Docker.

## Features

### Resource Management
- **`make pause-cluster`** - Pause all cluster containers to free CPU/memory
- **`make unpause-cluster`** - Resume paused containers
- **`make stop-cluster`** - Stop containers (preserves state, faster than recreation)
- **`make start-cluster`** - Start stopped containers
- **`make sleep-mode`** - Complete sleep mode (kills port-forwards + pauses containers)
- **`make wake-up`** - Wake from sleep mode

### Monitoring
- **`make cluster-status`** - Show container status and resource usage
- **`make resource-usage`** - Show overall Docker system resource usage
- **`make watch-resources`** - Continuously monitor resources (Ctrl+C to stop)
- **`make cluster-logs`** - Show logs from all cluster containers

### Cleanup
- **`make cleanup-docker`** - Clean unused Docker resources (safe)
- **`make cleanup-docker-aggressive`** - Remove ALL unused images (aggressive)

## Usage in Other Projects

To use this in another project's Makefile:

1. Copy `kind-resource-management.mk` to your project's directory
2. Add these lines to your Makefile:

```makefile
# Set your cluster name
KIND_CLUSTER_NAME = your-cluster-name

# Include resource management targets
include kind-resource-management.mk
```

3. Optionally override the cluster name if different from your makefile's naming

## Example Integration

```makefile
SHELL ?= /bin/bash

# Your existing variables...
KIND_CLUSTER_NAME = my-project-cluster

# Include reusable resource management
include kind-resource-management.mk

# Your existing targets...
.PHONY: build-cluster
build-cluster:
    kind create cluster --name $(KIND_CLUSTER_NAME) --config kind-config.yaml
    
# Now you automatically have access to:
# make pause-cluster, make sleep-mode, make cluster-status, etc.
```

## Typical Workflow

**Development active:**
```bash
make build-all      # Build and start everything
make all-pf         # Set up port forwards
# ... do development work ...
```

**Taking a break:**
```bash
make sleep-mode     # Free up CPU/memory, kill port forwards
```

**Resume development:**
```bash
make wake-up        # Resume containers
make all-pf         # Restore port forwards
```

**End of day:**
```bash
make stop-cluster   # Stop but preserve state
# OR
make rm-kind        # Completely remove if you want fresh start tomorrow
```

## Benefits Over macOS Docker Desktop

- **Granular Control**: Pause/resume individual cluster containers vs all-or-nothing VM
- **Resource Visibility**: See exactly which containers are using resources
- **Faster Resume**: Paused containers resume instantly vs VM boot time
- **State Preservation**: Stop/start preserves all cluster state
- **Monitoring**: Built-in resource monitoring and logging