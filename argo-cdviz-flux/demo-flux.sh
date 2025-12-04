#!/bin/bash
#
# FluxCD Status Demo
# Shows the status of FluxCD controllers and managed resources
#
# Uses demo-magic for interactive presentation
# https://github.com/paxtonhare/demo-magic
#

########################
# Configure demo-magic
########################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/demo-magic.sh"

# Speed up the typing for demo
TYPE_SPEED=30

# Custom prompt
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}$ "

########################
# Demo starts here
########################

clear

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}       FluxCD Environment Status                                ${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}FluxCD is deployed by ArgoCD (GitOps managing GitOps).${COLOR_RESET}"
echo -e "${WHITE}FluxCD manages the guestbook application in the flux-apps namespace.${COLOR_RESET}"
echo ""

# Step 1: Show Flux controllers
pe "# FluxCD Controllers running in flux-system namespace"
pe "kubectl get pods -n flux-system"

echo ""

# Step 2: Show GitRepositories
pe "# GitRepository sources - where FluxCD pulls manifests from"
pe "kubectl get gitrepository -n flux-system"

echo ""

# Step 3: Show Kustomizations
pe "# Kustomizations - what FluxCD is reconciling"
pe "kubectl get kustomization -n flux-system"

echo ""

# Step 4: Show CDEvents Receiver
pe "# CDEvents Receiver - allows external systems to trigger reconciliation"
pe "kubectl get receiver -n flux-system"

echo ""

# Step 5: Show flux-managed apps
pe "# Applications managed by FluxCD (flux-apps namespace)"
pe "kubectl get pods -n flux-apps"

echo ""

# Step 6: Show the guestbook service
pe "# Guestbook service deployed by FluxCD"
pe "kubectl get svc -n flux-apps"

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}FluxCD environment overview complete!${COLOR_RESET}"
echo ""
echo -e "${WHITE}Architecture:${COLOR_RESET}"
echo -e "  ArgoCD ${CYAN}──deploys──▶${COLOR_RESET} FluxCD ${CYAN}──manages──▶${COLOR_RESET} guestbook"
echo -e "  (wave 1)              (flux-system)         (flux-apps)"
echo ""
