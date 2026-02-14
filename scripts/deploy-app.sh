#!/usr/bin/env bash
set -euo pipefail

# --------- Pretty output ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${YELLOW}➜${NC} $*"; }
ok()   { echo -e "${GREEN}✅${NC} $*"; }
fail() { echo -e "${RED}❌${NC} $*"; exit 1; }

# --------- Resolve paths from script location ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NAMESPACE="retail-app"
RELEASE="retail-store"

CHART_DIR="$PROJECT_ROOT/kubernetes/helm/retail-store-sample"
VALUES_FILE="$CHART_DIR/values.yaml"
SECRETS_FILE="$CHART_DIR/values-secrets.yaml"

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}Deploying Retail Store App${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""

# --------- Preconditions ----------
command -v kubectl >/dev/null 2>&1 || fail "kubectl not found"
command -v helm   >/dev/null 2>&1 || fail "helm not found"

log "Checking cluster connectivity..."
kubectl cluster-info >/dev/null 2>&1 || fail "kubectl not configured or cluster unreachable"
ok "Cluster reachable"

log "Ensuring namespace exists: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
ok "Namespace ready"

# --------- Validate chart + values ----------
[ -d "$CHART_DIR" ]      || fail "Chart directory not found: $CHART_DIR"
[ -f "$VALUES_FILE" ]    || fail "values.yaml not found: $VALUES_FILE"
[ -f "$SECRETS_FILE" ]   || fail "values-secrets.yaml not found: $SECRETS_FILE (DO NOT COMMIT THIS FILE)"

log "Linting chart..."
helm lint "$CHART_DIR" >/dev/null || fail "helm lint failed"
ok "Helm chart lint passed"

# Optional but helpful: ensure dependencies are built (especially after editing Chart.yaml)
log "Building chart dependencies (safe even if already built)..."
( cd "$CHART_DIR" && helm dependency build . ) >/dev/null || fail "helm dependency build failed"
ok "Dependencies ready"

# --------- Install / Upgrade ----------
if helm status "$RELEASE" -n "$NAMESPACE" >/dev/null 2>&1; then
  log "Helm release exists. Upgrading: $RELEASE"
  helm upgrade "$RELEASE" "$CHART_DIR" \
    -n "$NAMESPACE" \
    -f "$VALUES_FILE" \
    -f "$SECRETS_FILE" \
    --wait --timeout 20m
  ok "Application upgraded"
else
  log "Installing release: $RELEASE"
  helm install "$RELEASE" "$CHART_DIR" \
    -n "$NAMESPACE" \
    -f "$VALUES_FILE" \
    -f "$SECRETS_FILE" \
    --wait --timeout 20m
  ok "Application installed"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "Check pods:"
echo -e "  ${YELLOW}kubectl get pods -n $NAMESPACE${NC}"
echo ""
echo -e "Access UI (port-forward):"
echo -e "  ${YELLOW}kubectl -n $NAMESPACE port-forward svc/retail-store-ui 9090:80${NC}"
echo -e "  Then open: ${YELLOW}http://localhost:9090${NC}"
echo ""
