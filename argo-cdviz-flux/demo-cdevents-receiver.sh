#!/bin/bash
#
# FluxCD CDEvents Receiver Demo
# Demonstrates FluxCD receiving CDEvents to trigger reconciliation
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

# Receiver webhook path
WEBHOOK_PATH="/hook/b03d83bad7059c66afcf5b0775c3d0dedceba102591a76c136b0c0820bf97087"
WEBHOOK_URL="http://localhost:9292${WEBHOOK_PATH}"

########################
# Demo starts here
########################

clear

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}       FluxCD CDEvents Receiver Demo                            ${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}This demo shows FluxCD receiving CDEvents to trigger reconciliation.${COLOR_RESET}"
echo -e "${WHITE}FluxCD's notification-controller supports the 'cdevents' receiver type.${COLOR_RESET}"
echo ""

# Check prerequisites silently
if ! kubectl get receiver cdevents-receiver -n flux-system &>/dev/null; then
    echo -e "${RED}ERROR: CDEvents receiver not found. Is FluxCD deployed?${NC}"
    exit 1
fi

if ! curl -s --connect-timeout 2 http://localhost:9292 &>/dev/null; then
    echo -e "${BROWN}Starting port-forward to notification-controller...${COLOR_RESET}"
    kubectl port-forward -n flux-system svc/notification-controller 9292:80 &>/dev/null &
    sleep 2
fi

echo -e "${GREEN}✓ Prerequisites verified${COLOR_RESET}"
echo ""
wait

# Step 1: Show the CDEvents Receiver configuration
p "# First, let's look at the CDEvents Receiver configuration"
pe "kubectl get receiver cdevents-receiver -n flux-system -o yaml | head -20"

echo ""
wait

# Step 2: Show current Kustomization status
p "# Check the current Kustomization status (last reconciliation time)"
pe "kubectl get kustomization guestbook-flux -n flux-system"

echo ""
wait

# Step 3: Show what we're about to send
p "# Now let's send a CDEvent to trigger reconciliation"
echo ""
echo -e "${BROWN}CDEvent Payload (dev.cdevents.service.deployed):${COLOR_RESET}"
cat <<'EOF'
{
  "context": {
    "version": "0.4.1",
    "id": "gitopscon-demo-<timestamp>",
    "source": "/gitopscon/demo",
    "type": "dev.cdevents.service.deployed.0.2.0",
    "timestamp": "<current-time>"
  },
  "subject": {
    "id": "guestbook-service",
    "type": "service",
    "content": {
      "environment": { "id": "flux-apps" }
    }
  }
}
EOF
echo ""
wait

# Step 4: Send the CDEvent
p "# Send the CDEvent to FluxCD's receiver webhook"

# Build the actual payload with current timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EVENT_ID="gitopscon-demo-$(date +%s)"

# Show the curl command (simplified for readability)
pe "curl -s -w '\\nHTTP Status: %{http_code}\\n' -X POST 'http://localhost:9292${WEBHOOK_PATH}' -H 'Content-Type: application/json' -d '{\"context\":{\"version\":\"0.4.1\",\"id\":\"${EVENT_ID}\",\"source\":\"/gitopscon/demo\",\"type\":\"dev.cdevents.service.deployed.0.2.0\",\"timestamp\":\"${TIMESTAMP}\"},\"subject\":{\"id\":\"guestbook-service\",\"type\":\"service\",\"content\":{\"environment\":{\"id\":\"flux-apps\"}}}}'"

echo ""
wait

# Step 5: Check if reconciliation was triggered
p "# Check if Kustomization was reconciled (notice the updated timestamp)"
pe "kubectl get kustomization guestbook-flux -n flux-system"

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Demo complete!${COLOR_RESET}"
echo ""
echo -e "${WHITE}Key takeaways:${COLOR_RESET}"
echo -e "  • FluxCD can ${GREEN}receive${COLOR_RESET} CDEvents via the Receiver API"
echo -e "  • CDEvents trigger immediate reconciliation of linked resources"
echo ""


