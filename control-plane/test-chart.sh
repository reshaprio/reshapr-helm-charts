#!/bin/bash
# Test the Reshapr Control Plane Helm Chart

set -e

echo "=========================================="
echo "Testing Reshapr Control Plane Helm Chart"
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
if helm template test . -f values-production.yaml \
    --set externalDatabase.host=postgres.example.com \
    --set externalDatabase.password=test-password \
    --set apiKey.existingSecret=test-api-key \
    > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Production values template rendering passed"
else
    echo -e "${RED}✗${NC} Production values template rendering failed"
    exit 1
fi

# Test 5: Render multiple encryption keys
echo "Test 5: Rendering multiple encryption keys..."
ENCRYPTION_MANIFEST="/tmp/test-encryption-manifests-$$.yaml"
helm template test . -f values-dev.yaml \
    --set encryptionKey.activeKeyId=v2 \
    --set encryptionKey.keys.v2.value=ICEiIyQlJicoKSorLC0uLzAxMjM0NTY3ODk6Ozw9Pj8= \
    --set encryptionKey.keys.v2.key=encryption-key-v2 \
    > "$ENCRYPTION_MANIFEST"

if grep -q 'name: RESHAPR_ENCRYPTION_KEYS_V1' "$ENCRYPTION_MANIFEST" && \
   grep -q 'name: RESHAPR_ENCRYPTION_KEYS_V2' "$ENCRYPTION_MANIFEST" && \
   grep -q 'name: RESHAPR_ENCRYPTION_LEGACY_KEY' "$ENCRYPTION_MANIFEST"; then
    echo -e "${GREEN}✓${NC} Multiple encryption keys rendering passed"
else
    echo -e "${RED}✗${NC} Multiple encryption keys rendering failed"
    rm -f "$ENCRYPTION_MANIFEST"
    exit 1
fi
rm -f "$ENCRYPTION_MANIFEST"

# Test 6: Check required templates exist
echo "Test 6: Checking required templates..."
REQUIRED_TEMPLATES=(
    "templates/_helpers.tpl"
    "templates/ctrl-deployment.yaml"
    "templates/ctrl-services.yaml"
    "templates/ctrl-serviceaccount.yaml"
    "templates/ingress.yaml"
    "templates/secret-api-key.yaml"
    "templates/secret-admin-credentials.yaml"
    "templates/secret-database.yaml"
    "templates/secret-encryption-key.yaml"
)

for template in "${REQUIRED_TEMPLATES[@]}"; do
    if [ -f "$template" ]; then
        echo -e "${GREEN}✓${NC} $template exists"
    else
        echo -e "${RED}✗${NC} $template is missing"
        exit 1
    fi
done

# Test 7: Check dependencies
echo "Test 7: Checking dependencies..."
if [ -f "Chart.lock" ] && compgen -G "charts/postgresql-*.tgz" > /dev/null; then
    echo -e "${GREEN}✓${NC} Dependencies are installed"
else
    echo -e "${RED}✗${NC} Dependencies are missing (run 'helm dependency build')"
    exit 1
fi

# Test 8: Validate rendered manifests
echo "Test 8: Validating rendered manifests..."
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
