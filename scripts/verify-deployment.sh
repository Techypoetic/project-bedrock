#!/bin/bash
set -e

# Color definitions for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Core configuration
NS="retail-app"
RELEASE="retail-store"

UI_SVC="${RELEASE}-ui"
CATALOG_SVC="${RELEASE}-catalog"
CARTS_SVC="${RELEASE}-carts"
CHECKOUT_SVC="${RELEASE}-checkout"
ORDERS_SVC="${RELEASE}-orders"

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}Verifying Deployment${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""

# Verify cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
  echo -e "${RED}❌ Cluster not reachable${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Cluster reachable${NC}"

# Verify namespace exists
if ! kubectl get namespace "$NS" &> /dev/null; then
  echo -e "${RED}❌ Namespace ${NS} not found${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Namespace ${NS} exists${NC}"

# Verify Helm release
if ! helm list -n "$NS" | grep -q "$RELEASE"; then
  echo -e "${RED}❌ Helm release '${RELEASE}' not found${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Helm release '${RELEASE}' found${NC}"
helm status "$RELEASE" -n "$NS" || true

# Validate pod status
TOTAL_PODS=$(kubectl get pods -n "$NS" --no-headers | wc -l | tr -d ' ')
RUNNING_PODS=$(kubectl get pods -n "$NS" --no-headers | awk '$3=="Running"{c++} END{print c+0}')

echo -e "Total pods:   ${YELLOW}${TOTAL_PODS}${NC}"
echo -e "Running pods: ${YELLOW}${RUNNING_PODS}${NC}"

if [ "$TOTAL_PODS" -ne "$RUNNING_PODS" ]; then
  echo -e "${RED}❌ Not all pods are running${NC}"
  kubectl get pods -n "$NS"
  exit 1
fi
echo -e "${GREEN}✅ All pods are running${NC}"

# List services
kubectl get svc -n "$NS"

# Ensure required services exist
for svc in "$UI_SVC" "$CATALOG_SVC" "$CARTS_SVC" "$CHECKOUT_SVC" "$ORDERS_SVC"; do
  if ! kubectl get svc -n "$NS" "$svc" &>/dev/null; then
    echo -e "${RED}❌ Missing service: ${svc}${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ Found service: ${svc}${NC}"
done

# Validate deployment readiness
NOT_READY=$(kubectl get deployments -n "$NS" --no-headers | awk '$2 != $3 {print $1}')
if [ -n "$NOT_READY" ]; then
  echo -e "${RED}❌ Some deployments are not ready:${NC}"
  echo "$NOT_READY"
  exit 1
fi
echo -e "${GREEN}✅ All deployments are ready${NC}"

# Show StatefulSets and PVC status
kubectl get statefulsets -n "$NS"
kubectl get pvc -n "$NS"

# Internal service connectivity check from UI pod
UI_POD=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name=ui -o jsonpath='{.items[0].metadata.name}')

if [ -z "$UI_POD" ]; then
  echo -e "${RED}❌ UI pod not found${NC}"
  exit 1
fi

for svc in "$CATALOG_SVC" "$CARTS_SVC" "$CHECKOUT_SVC" "$ORDERS_SVC"; do
  if ! kubectl exec -n "$NS" "$UI_POD" -- sh -c "wget -q -O- http://$svc >/dev/null 2>&1"; then
    echo -e "${RED}❌ Not reachable from UI pod: ${svc}${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ Reachable from UI pod: ${svc}${NC}"
done

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Verification Complete!${NC}"
echo -e "${GREEN}================================${NC}"
