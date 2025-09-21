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

- **ArgoCD UI**: http://localhost:8080 (admin/password shown in terminal)
- **CDViz**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:8081 (admin/password shown in terminal)

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

CDViz is configured to connect to the local ArgoCD instance. After deployment, you'll need to:

1. Get an ArgoCD API token:
   ```sh
   # Login to ArgoCD CLI
   argocd login localhost:8080 --username admin --password <password>

   # Generate a token
   argocd account generate-token
   ```

2. Configure CDViz with the token (update the CDViz application in ArgoCD)

## Requirements

- Docker
- kubectl
- helm
- kind
- kubectx
- make

## Architecture

The project uses a GitOps approach with ArgoCD managing all applications:

1. **ArgoCD** - GitOps continuous delivery tool (sync-wave: 0)
2. **Prometheus Stack** - Monitoring and alerting (sync-wave: 1)
3. **CDViz** - Pipeline visualization and monitoring (sync-wave: 2)
4. **App-of-Apps** - Meta application managing other apps (sync-wave: 3)

## Troubleshooting

### Port Forwarding Issues
If port forwarding stops working:
```sh
make kill-port-forwards
make all-pf
```

### CDViz Connection Issues
Ensure CDViz has the correct ArgoCD token configured. Check the CDViz logs:
```sh
kubectl logs -n cdviz deployment/cdviz
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