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
kind-cluster: vendor ## build a kind cluster of 3 worker nodes, k8s 1.24
	kind create cluster --name argo-homelab --image=kindest/node:v1.29.0 --wait 1m --config kind/kind-config.yaml --retain

# .PHONY: kind-destroy-helmfile
# kind-destroy-helmfile: ## helmfile destroy a cluster
# 	helmfile -e kind destroy

.PHONY: rm-kind
rm-kind: ## delete a kind cluster
	kind delete cluster --name argo-homelab

.PHONY: vcluster-init
vcluster-init: vendor ## create 3 vclusters
	kubectx kind-argo-homelab
	vcluster create vc1 --upgrade --connect=false --distro k8s -f vc1-values.yaml
	vcluster create vc2 --upgrade --connect=false --distro k8s -f vc2-values.yaml
	vcluster create vc3 --upgrade --connect=false --distro k8s -f vc3-values.yaml

.PHONY: argo-init
argo-init: vendor ## init ArgoCD to KinD cluster
	kubectx kind-argo-homelab
	helm repo add argo https://argoproj.github.io/argo-helm || true
	helm install argocd argo/argo-cd -n argocd --create-namespace -f ../argocd/values.override.yaml

.PHONY: argo-bootstrap
argo-bootstrap: vendor ## bootstrap ArgoCD-Apps/app-of-apps to KinD cluster
	kubectx kind-argo-homelab
	helm repo add argo https://argoproj.github.io/argo-helm || true
	helm upgrade -i argocd-apps argo/argocd-apps -n argocd --create-namespace -f ../argocd-apps/values.override.yaml	

.PHONY: kyverno-init
kyverno-init: ## install kyverno and apply argo policy
	kubectx kind-argo-homelab
	helm repo add kyverno https://kyverno.github.io/kyverno/ || true
	helm install kyverno kyverno/kyverno -n kyverno --create-namespace
	kubectl apply -f kyverno/policy.yaml

.PHONY: argo-pf
argo-pf: ## get admin and port forward ArgoCD
	kubectx kind-argo-homelab
	kubectl get secret argocd-initial-admin-secret --template={{.data.password}} -n argocd | base64 -D
	@echo "";
	kubectl port-forward svc/argocd-server -n argocd 8080:80



.PHONY: argo-ap-bootstrap
argo-ap-bootstrap: vendor ## bootstrap ArgoCD to KinD cluster
	kubectx kind-kind-argocd
	argocd-autopilot repo bootstrap

.PHONY: argo-ap-project
argo-ap-project: vendor ## bootstrap ArgoCD to KinD cluster
	kubectx kind-kind-argocd
	argocd-autopilot project create monitoring

.PHONY: argo-ap-app
argo-ap-app: vendor ## bootstrap ArgoCD to KinD cluster
	kubectx kind-kind-argocd
	argocd-autopilot project create testing
	argocd-autopilot app create hello-world --app github.com/argoproj-labs/argocd-autopilot/examples/demo-app/ -p testing --wait-timeout 2m



### check software available
HAS_KUBECTL      := $(shell command -v kubectl;)
HAS_KUBECTX      := $(shell command -v kubectx;)
HAS_HELM          := $(shell command -v helm;)
HAS_KIND          := $(shell command -v kind;)
HAS_ARGO_PILOT          := $(shell command -v argocd-autopilot;)
HAS_VCLUSTER          := $(shell command -v vcluster;)

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
ifndef HAS_ARGO_PILOT
	$(error must install argocd-autopilot)
endif
ifndef HAS_VCLUSTER
	$(error must install argocd-autopilot)
endif