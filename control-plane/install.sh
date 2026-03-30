#!/bin/bash
# Install Reshapr Control Plane Chart
    
set -e

NAMESPACE="${NAMESPACE:-reshapr-system}"
RELEASE_NAME="${RELEASE_NAME:-reshapr-control-plane}"
VALUES_FILE="${VALUES_FILE:-values-dev.yaml}"

echo "===================================="
echo "Reshapr Control Plane Installation"
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

# Add bitnami repo for PostgreSQL dependency
echo "Adding bitnami repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update

# Build dependencies
echo "Building chart dependencies..."
helm dependency build .

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
echo "To access the services (if ingress is not enabled):"
echo "  # Control Plane API"
echo "  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE_NAME}-ctrl 5555:5555"
echo ""
echo "  # Authorization (Keycloak)"
echo "  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE_NAME}-authz 8080:8080"
echo ""
