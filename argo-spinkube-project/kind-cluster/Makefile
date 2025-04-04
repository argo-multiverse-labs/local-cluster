SHELL ?= /bin/bash
RED=\033[0;31m
NC=\033[0m
################################################################################
# Setup and Help                                                               #
################################################################################

.PHONY: help
help: vendor ## This help.\	
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: kind-cluster
kind-cluster: vendor ## build a kind cluster of 3 worker nodes, k8s 1.32
	kind create cluster --name argo-homelab-spin --image=kindest/node:v1.32.2 --wait 1m --config kind/kind-config.yaml --retain

# .PHONY: kind-destroy-helmfile
# kind-destroy-helmfile: ## helmfile destroy a cluster
# 	helmfile -e kind destroy

.PHONY: rm-kind
rm-kind: ## delete a kind cluster
	kind delete cluster --name argo-homelab-spin

# .PHONY: vcluster-init
# vcluster-init: vendor ## create 3 vclusters
# 	kubectx kind-argo-homelab
# 	vcluster create vc1 --upgrade --connect=false --distro k8s -f vc1-values.yaml
# 	vcluster create vc2 --upgrade --connect=false --distro k8s -f vc2-values.yaml
# 	vcluster create vc3 --upgrade --connect=false --distro k8s -f vc3-values.yaml

.PHONY: argo-init
argo-init: vendor ## init ArgoCD to KinD cluster
	kubectx kind-argo-homelab-spin
	helm repo add argo https://argoproj.github.io/argo-helm || true
	helm install argocd argo/argo-cd -n argocd --create-namespace -f ../argocd/values.override.yaml

.PHONY: argo-bootstrap
argo-bootstrap: vendor ## bootstrap ArgoCD-Apps/app-of-apps to KinD cluster
	kubectx kind-argo-homelab-spin
	helm repo add argo https://argoproj.github.io/argo-helm || true
	helm upgrade -i argocd-apps argo/argocd-apps -n argocd --create-namespace -f ../argocd-apps/values.override.yaml	


.PHONY: argo-pf
argo-pf: ## get admin and port forward ArgoCD
	kubectx kind-argo-homelab-spin
	kubectl get secret argocd-initial-admin-secret --template={{.data.password}} -n argocd | base64 -D
	@echo "";
	kubectl port-forward svc/argocd-server -n argocd 8080:80

.PHONY: all-pf
all-pf: kill-port-forwards ## port forward ArgoCD and Prometheus
	kubectx kind-argo-homelab-spin
	kubectl get secret argocd-initial-admin-secret --template={{.data.password}} -n argocd | base64 -D
	@echo "";
	kubectl get secret prometheus-grafana -ogo-template='{{ index .data "admin-password" | base64decode }}' -n prometheus
	@echo "";
	kubectl port-forward svc/argocd-server -n argocd 8080:80 & kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n prometheus 9090:9090 & kubectl port-forward svc/prometheus-grafana -n prometheus 8081:80 & kubectl port-forward svc/simple-spinapp -n spin-apps 8083:80

.PHONY: kill-port-forwards

kill-port-forwards: ## kill all port forwards
	@echo "Finding and killing kubectl port-forward processes..."
	@pids=$$(ps aux | grep "kubectl port-forward" | grep -v grep | awk '{print $$2}'); \
	if [ -z "$$pids" ]; then \
		echo "No kubectl port-forward processes found."; \
	else \
		echo "Killing processes: $$pids"; \
		echo $$pids | xargs kill -9; \
		echo "All kubectl port-forward processes have been terminated."; \
	fi

.PHONY: build-all
build-all: vendor kind-cluster ## create kind cluster, bootstrap argocd, bootstrap argocd-apps, port forward argocd
	$(MAKE) argo-init
	sleep 30s
	$(MAKE) argo-bootstrap
	sleep 30s
	$(MAKE) all-pf


### check software available
HAS_KUBECTL      := $(shell command -v kubectl;)
HAS_KUBECTX      := $(shell command -v kubectx;)
HAS_HELM          := $(shell command -v helm;)
HAS_KIND          := $(shell command -v kind;)
# HAS_VCLUSTER          := $(shell command -v vcluster;)

.PHONY: vendor
vendor: ## Preflight checks
ifndef HAS_KUBECTL
	$(error You must install kubectl)
endif
ifndef HAS_HELM
	$(error must install helm)
endif
ifndef HAS_KUBECTX
	$(error must install kubectx)
endif
ifndef HAS_KIND
	$(error must install kind)
endif
# ifndef HAS_VCLUSTER
# 	$(error must install argocd-autopilot)
# endif