#!/bin/bash
# Test the Reshapr Web UI Helm Chart

set -e

echo "=========================================="
echo "Testing Reshapr Web UI Helm Chart"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test 1: Lint the chart
echo "Test 1: Linting chart..."
if helm lint . > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Chart lint passed"
else
    echo -e "${RED}✗${NC} Chart lint failed"
    exit 1
fi

# Test 2: Template with default values
echo "Test 2: Rendering templates with default values..."
if helm template test . > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Default values template rendering passed"
else
    echo -e "${RED}✗${NC} Default values template rendering failed"
    exit 1
fi

# Test 3: Template with dev values
echo "Test 3: Rendering templates with dev values..."
if helm template test . -f values-dev.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Dev values template rendering passed"
else
    echo -e "${RED}✗${NC} Dev values template rendering failed"
    exit 1
fi

# Test 4: Template with production values
echo "Test 4: Rendering templates with production values..."
if helm template test . -f values-production.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Production values template rendering passed"
else
    echo -e "${RED}✗${NC} Production values template rendering failed"
    exit 1
fi

# Test 5: Validate the request body size default and override
echo "Test 5: Validating BODY_SIZE_LIMIT configuration..."
DEFAULT_MANIFEST=$(helm template test .)
OVERRIDE_MANIFEST=$(helm template test . \
    --set 'extraEnv[0].name=BODY_SIZE_LIMIT' \
    --set 'extraEnv[0].value=24M')

if [ "$(echo "$DEFAULT_MANIFEST" | grep -c 'name: BODY_SIZE_LIMIT')" -eq 1 ] && \
    echo "$DEFAULT_MANIFEST" | grep -A1 'name: BODY_SIZE_LIMIT' | grep -q 'value: "12M"' && \
    [ "$(echo "$OVERRIDE_MANIFEST" | grep -c 'name: BODY_SIZE_LIMIT')" -eq 1 ] && \
    echo "$OVERRIDE_MANIFEST" | grep -A1 'name: BODY_SIZE_LIMIT' | grep -q 'value: 24M'; then
    echo -e "${GREEN}✓${NC} BODY_SIZE_LIMIT default and override passed"
else
    echo -e "${RED}✗${NC} BODY_SIZE_LIMIT default or override failed"
    exit 1
fi

# Test 6: Check required templates exist
echo "Test 6: Checking required templates..."
REQUIRED_TEMPLATES=(
    "templates/_helpers.tpl"
    "templates/deployment.yaml"
    "templates/service.yaml"
    "templates/serviceaccount.yaml"
    "templates/ingress.yaml"
    "templates/secret.yaml"
    "templates/pdb.yaml"
)

for template in "${REQUIRED_TEMPLATES[@]}"; do
    if [ -f "$template" ]; then
        echo -e "${GREEN}✓${NC} $template exists"
    else
        echo -e "${RED}✗${NC} $template is missing"
        exit 1
    fi
done

# Test 7: Validate rendered manifests
echo "Test 7: Validating rendered manifests..."
MANIFEST_FILE="/tmp/test-manifests-$$.yaml"
helm template test . -f values-dev.yaml > "$MANIFEST_FILE"

# Count resources
echo "  - Deployments found: $(grep -c 'kind: Deployment' "$MANIFEST_FILE")"
echo "  - Services found: $(grep -c 'kind: Service' "$MANIFEST_FILE")"
echo "  - Secrets found: $(grep -c 'kind: Secret' "$MANIFEST_FILE")"
echo "  - ServiceAccounts found: $(grep -c 'kind: ServiceAccount' "$MANIFEST_FILE")"

rm -f "$MANIFEST_FILE"

echo -e "${GREEN}✓${NC} Manifest validation passed"

echo ""
echo "=========================================="
echo -e "${GREEN}All tests passed!${NC}"
echo "=========================================="
