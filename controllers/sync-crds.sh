#!/usr/bin/env bash
set -euo pipefail

echo "Fetching latest CRDs from reshapr-controllers repository..."

CRD_URL_BASE="https://raw.githubusercontent.com/reshaprio/reshapr-controllers/main/deploy/crd"

curl -sSL "$CRD_URL_BASE/services.reshapr.io-v1.yml" -o crds/services.reshapr.io-v1.yml

echo "Done."
