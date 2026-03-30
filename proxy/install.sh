#!/bin/bash
# Install Reshapr Proxy Chart

set -e

NAMESPACE="${NAMESPACE:-reshapr-proxy}"
RELEASE_NAME="${RELEASE_NAME:-reshapr-proxy}"
VALUES_FILE="${VALUES_FILE:-values-dev.yaml}"

echo "===================================="
echo "Reshapr Proxy Installation"
echo "===================================="
echo ""
echo "Release Name: ${RELEASE_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Values File: ${VALUES_FILE}"
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed. Please install helm first."
    exit 1
fi

# Check if namespace exists, create if not
if ! kubectl get namespace "${NAMESPACE}" &> /dev/null; then
    echo "Creating namespace ${NAMESPACE}..."
    kubectl create namespace "${NAMESPACE}"
fi

# Install or upgrade the chart
if helm list -n "${NAMESPACE}" | grep -q "${RELEASE_NAME}"; then
    echo "Upgrading existing installation..."
    helm upgrade "${RELEASE_NAME}" . \
        --namespace "${NAMESPACE}" \
        -f "${VALUES_FILE}" \
        --wait
else
    echo "Installing chart..."
    helm install "${RELEASE_NAME}" . \
        --namespace "${NAMESPACE}" \
        -f "${VALUES_FILE}" \
        --wait
fi

echo ""
echo "===================================="
echo "Installation complete!"
echo "===================================="
echo ""
echo "To check the status:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo ""
echo "To view gateway logs:"
echo "  kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/instance=${RELEASE_NAME} -f"
echo ""
echo "To access the gateway (if ingress is not enabled):"
echo "  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE_NAME} 7777:7777"
echo ""
