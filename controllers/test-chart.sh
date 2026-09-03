#!/bin/bash
# Test the Reshapr Controllers Helm Chart

set -e

echo "=========================================="
echo "Testing Reshapr Controllers Helm Chart"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test 1: Lint the chart
echo "Test 1: Linting chart..."
if helm lint . > /dev/null 2>&1; then
    echo -e "${GREEN}\xe2\x9c\x93${NC} Chart lint passed"
else
    echo -e "${RED}\xe2\x9c\x97${NC} Chart lint failed"
    exit 1
fi

# Test 2: Template with default values (both components)
echo "Test 2: Rendering templates with default values..."
if helm template test . > /dev/null 2>&1; then
    echo -e "${GREEN}\xe2\x9c\x93${NC} Default values template rendering passed"
else
    echo -e "${RED}\xe2\x9c\x97${NC} Default values template rendering failed"
    exit 1
fi

# Test 3: Operator only
echo "Test 3: Rendering operator-only..."
if helm template test . --set admissionController.enabled=false > /dev/null 2>&1; then
    echo -e "${GREEN}\xe2\x9c\x93${NC} Operator-only rendering passed"
else
    echo -e "${RED}\xe2\x9c\x97${NC} Operator-only rendering failed"
    exit 1
fi

# Test 4: Admission only
echo "Test 4: Rendering admission-only..."
if helm template test . --set operator.enabled=false > /dev/null 2>&1; then
    echo -e "${GREEN}\xe2\x9c\x93${NC} Admission-only rendering passed"
else
    echo -e "${RED}\xe2\x9c\x97${NC} Admission-only rendering failed"
    exit 1
fi

# Test 5: Certificate providers
echo "Test 5: Rendering each certificate provider..."
for provider in cert-manager openshift existing; do
    if helm template test . \
        --set admissionController.certificate.provider=${provider} \
        --set admissionController.certificate.caBundle=Zm9v \
        > /dev/null 2>&1; then
        echo -e "${GREEN}\xe2\x9c\x93${NC} Provider '${provider}' rendering passed"
    else
        echo -e "${RED}\xe2\x9c\x97${NC} Provider '${provider}' rendering failed"
        exit 1
    fi
done

# Test 6: Dev and production values
echo "Test 6: Rendering with dev and production values..."
for f in values-dev.yaml values-production.yaml; do
    if helm template test . -f "$f" > /dev/null 2>&1; then
        echo -e "${GREEN}\xe2\x9c\x93${NC} $f rendering passed"
    else
        echo -e "${RED}\xe2\x9c\x97${NC} $f rendering failed"
        exit 1
    fi
done

# Test 7: Check required templates exist
echo "Test 7: Checking required templates..."
REQUIRED_TEMPLATES=(
    "templates/_helpers.tpl"
    "templates/operator-deployment.yaml"
    "templates/operator-rbac.yaml"
    "templates/admission-deployment.yaml"
    "templates/admission-rbac.yaml"
    "templates/admission-service.yaml"
    "templates/admission-webhook-config.yaml"
    "templates/NOTES.txt"
)

for template in "${REQUIRED_TEMPLATES[@]}"; do
    if [ -f "$template" ]; then
        echo -e "${GREEN}\xe2\x9c\x93${NC} $template exists"
    else
        echo -e "${RED}\xe2\x9c\x97${NC} $template is missing"
        exit 1
    fi
done

echo ""
echo -e "${GREEN}All tests passed!${NC}"
