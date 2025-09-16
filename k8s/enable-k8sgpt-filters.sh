#!/bin/bash
set -euo pipefail

# Namespace where k8sgpt is running
NAMESPACE="default"

# Detect the first k8sgpt pod
POD=$(kubectl get pods -n "$NAMESPACE" -l app=k8sgpt -o jsonpath='{.items[0].metadata.name}')

# Filters you want to enable
FILTERS=(
  "Gateway"
  "Storage"
  "HorizontalPodAutoscaler"
  "PodDisruptionBudget"
  "NetworkPolicy"
  "Log"
  "GatewayClass"
  "HTTPRoute"
  "Security"
)

echo "Enabling filters on pod: $POD in namespace: $NAMESPACE"
for f in "${FILTERS[@]}"; do
  echo ">> Adding filter: $f"
  kubectl exec -n "$NAMESPACE" -it "$POD" -- /k8sgpt filter add "$f" || echo "Failed to add $f"
done

echo "✅ All filters processed."
echo
echo "Current filter status:"
kubectl exec -n "$NAMESPACE" -it "$POD" -- /k8sgpt filters list
