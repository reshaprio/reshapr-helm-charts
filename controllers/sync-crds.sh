#!/usr/bin/env bash
set -euo pipefail

# Sync the CRDs shipped by the chart with the ones from the upstream reshapr-controllers repository.
# Run from the chart directory: ./sync-crds.sh

REF="${REF:-main}"
CRD_URL_BASE="https://raw.githubusercontent.com/reshaprio/reshapr-controllers/${REF}/deploy/crd"

CRDS=(
  configurationplans.reshapr.io-v1.yml
  customtools.reshapr.io-v1.yml
  expositions.reshapr.io-v1.yml
  gatewaygroups.reshapr.io-v1.yml
  resources.reshapr.io-v1.yml
  secretsources.reshapr.io-v1.yml
  services.reshapr.io-v1.yml
)

echo "Fetching CRDs from reshapr-controllers@${REF} ..."
for crd in "${CRDS[@]}"; do
  echo "  - ${crd}"
  curl -fsSL "${CRD_URL_BASE}/${crd}" -o "crds/${crd}"
done

echo "Done. ${#CRDS[@]} CRDs synced into ./crds/"
