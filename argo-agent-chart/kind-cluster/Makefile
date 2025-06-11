SHELL ?= /bin/bash
RED=\033[0;31m
NC=\033[0m

# Detect OS for base64 compatibility
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    BASE64_DECODE = base64 -D
else
    BASE64_DECODE = base64 -d
endif
################################################################################
# Setup and Help                                                               #
################################################################################

.PHONY: help
help: vendor ## This help.\	
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

.PHONY: kind-cluster
kind-cluster: vendor ## build a kind cluster of 3 worker nodes, k8s 1.32
	kind create cluster --name argo-agent-chart --image=kindest/node:v1.33.1 --wait 1m --config kind/kind-config.yaml --retain

.PHONY: rm-kind
rm-kind: ## delete a kind cluster
	kind delete cluster --name argo-agent-chart

.PHONY: argo-init
argo-init: vendor ## init ArgoCD to KinD cluster
	kubectx kind-argo-agent-chart
	helm repo add argo https://argoproj.github.io/argo-helm || true
	helm install argocd argo/argo-cd -n argocd --create-namespace -f ../argocd/values.override.yaml

.PHONY: argo-bootstrap
argo-bootstrap: vendor ## bootstrap ArgoCD-Apps/app-of-apps to KinD cluster
	kubectx kind-argo-agent-chart
	helm repo add argo https://argoproj.github.io/argo-helm || true
	helm upgrade -i argocd-apps argo/argocd-apps -n argocd --create-namespace -f ../argocd-apps/values.override.yaml	


.PHONY: argo-pf
argo-pf: ## get admin and port forward ArgoCD
	kubectx kind-argo-agent-chart
	kubectl get secret argocd-initial-admin-secret --template={{.data.password}} -n argocd | $(BASE64_DECODE)
	@echo "";
	kubectl port-forward svc/argocd-server -n argocd 8080:80

.PHONY: all-pf
all-pf: kill-port-forwards ## port forward ArgoCD and Prometheus
	kubectx kind-argo-agent-chart
	kubectl get secret argocd-initial-admin-secret --template={{.data.password}} -n argocd | $(BASE64_DECODE)
	@echo "";
	kubectl get secret prometheus-grafana -ogo-template='{{ index .data "admin-password" | base64decode }}' -n prometheus
	@echo "";
	kubectl port-forward svc/argocd-server -n argocd 8080:80 & kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n prometheus 9090:9090 & kubectl port-forward svc/prometheus-grafana -n prometheus 8081:80

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
	sleep 30
	$(MAKE) argo-bootstrap
	sleep 30
	$(MAKE) all-pf


### check software available
HAS_KUBECTL      := $(shell command -v kubectl;)
HAS_KUBECTX      := $(shell command -v kubectx;)
HAS_HELM          := $(shell command -v helm;)
HAS_KIND          := $(shell command -v kind;)

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