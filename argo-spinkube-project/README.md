# Argo Spinkube Project

Welcome to the Argo Spinkube Project! This project sets up a home lab cluster using KinD (Kubernetes in Docker) to start an ArgoCD instance, which then bootstraps all the necessary components to run SpinKube and SpinKube Apps.

## Getting Started

To get started, navigate to the `kind-cluster` folder and use the provided Makefile to build or clean up the cluster.

### Build the Cluster

To build the cluster and start everything, run the following command:

```sh
make build-all
```

This command will set up the KinD cluster, deploy ArgoCD, and bootstrap the SpinKube components and applications.

### Clean Up

To clean up the cluster, run:

```sh
make rm-kind
```

This will remove the KinD cluster and the resources created by the `make build-all` command.

## Folder Structure

```
.
├── argocd              ## contains Argo CD Helm Chart Values override
├── argocd-apps         ## App-of-Apps Argo CD config
├── kind-cluster        ## KinD configs and Makefile
├── kwasm-setup         ## Node annotations for KWASM
├── logdumps            ## Scripts to dump logs of pods
├── prometheus          ## Prom Dashboard for ArgoCD
├── spin-apps           ## Sample Spin Apps
└── spin-setup          ## Spin CRDs

```

## Requirements

- Docker
- Kubernetes CLI
- KinD
- Make

## Contributing

Feel free to open issues or submit pull requests if you have any improvements or bug fixes.

## License

This project is licensed under the MIT License.

Happy coding!