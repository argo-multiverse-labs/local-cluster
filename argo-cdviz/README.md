# Argo CDViz Project

Welcome to the Argo CDViz Project! This project sets up a home lab cluster using KinD (Kubernetes in Docker) to start an ArgoCD instance with CDViz for enhanced pipeline visibility and continuous delivery monitoring.

## Overview

CDViz (Continuous Delivery Visualization) provides real-time monitoring and visualization of your continuous delivery pipelines. This project integrates CDViz with ArgoCD to give you comprehensive visibility into your GitOps deployments.

## Getting Started

To get started, navigate to the `kind-cluster` folder and use the provided Makefile to build or clean up the cluster.

### Build the Cluster

To build the cluster and start everything, run the following command:

```sh
cd kind-cluster
make build-all
```

This command will:
1. Set up the KinD cluster with 3 worker nodes
2. Deploy ArgoCD
3. Bootstrap CDViz and other applications
4. Set up port forwarding for all services

### Access the Services

After running `make build-all`, the services will be available at:

- **ArgoCD UI**: http://localhost:8081 (admin/password shown in terminal)
- **CDViz Collector**: http://localhost:8080
  - **Webhook Endpoints**:
    - CDEvents: http://localhost:8080/webhook/000-cdevents
    - Kubewatch: http://localhost:8080/webhook/000-kubewatch
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/password shown in terminal)

### Clean Up

To clean up the cluster, run:

```sh
make rm-kind
```

This will remove the KinD cluster and all resources created by the `make build-all` command.

## Folder Structure

```
.
├── argocd              ## Contains Argo CD Helm Chart Values override
├── argocd-apps         ## App-of-Apps Argo CD configuration
├── kind-cluster        ## KinD configs and Makefile
├── logdumps            ## Scripts to dump logs of pods
└── prometheus          ## Prometheus Dashboard for ArgoCD
```

## Makefile Commands

- `make build-all` - Creates the entire environment (cluster + ArgoCD + CDViz)
- `make kind-cluster` - Creates just the KinD cluster
- `make argo-init` - Installs ArgoCD on existing cluster
- `make argo-bootstrap` - Bootstraps ArgoCD applications
- `make argo-pf` - Port forwards ArgoCD and shows admin password
- `make all-pf` - Port forwards all services (ArgoCD, CDViz, Prometheus, Grafana)
- `make kill-port-forwards` - Kills all kubectl port-forward processes
- `make rm-kind` - Deletes the KinD cluster

## CDViz Configuration

CDViz is deployed as three separate components:
- **cdviz-db**: PostgreSQL 17.2 with TimescaleDB extension for storing CDEvents data
- **cdviz-collector**: Main collector service that receives webhooks and processes CDEvents
- **cdviz-grafana**: Grafana dashboards and datasource configuration (integrates with existing Grafana from kube-prometheus-stack)

### Database Setup

The database is automatically configured using CloudNativePG operator with:
- PostgreSQL 17.2 with TimescaleDB extensions
- Automatic schema migrations via cdviz-db-migration job
- Proper secret management for database credentials

### Collector Configuration

The collector is configured to receive events from multiple sources:
- **CDEvents webhook**: Receives standard CDEvents via REST API
- **Kubewatch integration**: Monitors Kubernetes resource changes automatically
- **Debug sink**: Logs all received events for troubleshooting

### Grafana Integration

Grafana dashboards are automatically provisioned with:
- **Interactive Demo Forms**: Send test CDEvents directly from Grafana dashboards
- **Real-time Visualizations**: Track pipeline executions, deployments, and incidents
- **Direct Database Queries**: Dashboards query PostgreSQL directly for optimal performance

### Testing CDEvents

Use the Grafana dashboards to send test events:
1. Navigate to **Grafana**: http://localhost:3000
2. Open the "Demo Service Deployed" dashboard
3. Fill out the forms and click "Send" to POST events to the collector
4. Events are automatically stored in the database and visible in other dashboards

## Requirements

- Docker
- kubectl
- helm
- kind
- kubectx
- make

## Architecture

The project uses a GitOps approach with ArgoCD managing all applications via sync waves:

1. **ArgoCD** - GitOps continuous delivery tool (sync-wave: 0)
2. **Prometheus Stack** - Monitoring and alerting with Grafana (sync-wave: 1)
3. **CDViz Database** - PostgreSQL 17.2 + TimescaleDB with CloudNativePG (sync-wave: 2)
4. **CDViz Collector** - Event collection service with kubewatch integration (sync-wave: 3)
5. **CDViz Grafana** - Dashboard provisioning to existing Grafana instance (sync-wave: 4)

### Key Features Fixed

- ✅ **PostgreSQL Compatibility**: Fixed TimescaleDB extension compatibility with PostgreSQL 17.2
- ✅ **Namespace Integration**: CDViz Grafana dashboards properly deployed to prometheus namespace
- ✅ **Port Forwarding**: Corrected all port mappings in Makefile for proper local access
- ✅ **CORS Configuration**: Collector properly configured for browser-based POST requests
- ✅ **Secret Management**: Proper Kubernetes secret references throughout all charts
- ✅ **Kubewatch Monitoring**: Automatic Kubernetes resource change tracking enabled

## Troubleshooting

### Port Forwarding Issues
If port forwarding stops working or you get connection refused errors:
```sh
make kill-port-forwards
make all-pf
```

**Note**: The Makefile now uses the correct ports:
- ArgoCD: 8081 (not 8080)
- CDViz Collector: 8080
- Grafana: 3000 (not 8081)
- Prometheus: 9090

### CDViz Collector Issues
Check collector logs for webhook processing:
```sh
kubectl logs -n cdviz deployment/cdviz-collector
```

### Database Connection Issues
Verify database is running and migrations completed:
```sh
kubectl get pods -n cdviz
kubectl logs -n cdviz deployment/cdviz-db-migration
```

### Grafana Dashboard POST Errors
If you get "net::ERR_CONNECTION_REFUSED" when sending events from Grafana:
1. Ensure port forwarding is active: `make all-pf`
2. Verify collector is accessible: `curl http://localhost:8080/webhook/000-cdevents`
3. Check browser network tab for actual error details

### TimescaleDB Extension Issues
If you see "undefined symbol" errors, ensure using PostgreSQL 17.2:
```sh
kubectl get cluster -n cdviz cdviz-db -o yaml | grep imageName
```

## Contributing

Feel free to open issues or submit pull requests if you have any improvements or bug fixes.

## References

- [CDViz Documentation](https://cdviz.dev/docs/getting-started)
- [CDViz GitHub](https://github.com/cdviz-dev/cdviz)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Pipeline Visibility Article](https://dev.to/davidb31/pipeline-visibility-crisis-when-your-tools-dont-talk-3ch)

## License

This project is licensed under the MIT License.

Happy monitoring!