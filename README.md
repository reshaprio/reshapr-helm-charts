# reShapr Helm Charts

Helm Charts for installing reShapr components on Kubernetes

[![License](https://img.shields.io/github/license/microcks/microcks-testcontainers-java?style=for-the-badge&logo=apache)](https://www.apache.org/licenses/LICENSE-2.0)


## Build Status

Latest released version is `0.0.3`.

Current development version is `0.0.4`.

## How to use them?

This repository contains two Helm charts:

* The `reshapr-control-plane` Helm chart is dedicated to the installation of the reShapr control plane. It is distributed as an OCI artifact on https://quay.io/repository/reshapr/reshapr-helm-charts/reshapr-control-plane

* The `reshapr-proxy` Helm chart is dedicated to the installation of the reShapr oproxy. It is distributed as an OCI artifact on https://quay.io/repository/reshapr/reshapr-helm-charts/reshapr-proxy

### reShapr control plane

```sh
helm pull oci://quay.io/reshapr/reshapr-helm-charts/reshapr-control-plane --version 0.0.3

helm install reshapr-control-plane oci://quay.io/reshapr/reshapr-helm-charts/reshapr-control-plane --version 0.0.3 \
  --create-namespace --namespace reshapr-system \ 
  --set postgresql.enabled=true \
  --set postgresql.auth.password=admin \       
  --set postgresqlauthz.enabled=true \
  --set apiKey.value=dev-api-key-change-me-in-production \
  --set encryptionKey.value=dev-encryption-key-change-me-in-production \
  --set admin.nameValue=admin \
  --set admin.passwordValue=password \
  --set admin.emailValue=reshapr@example.com \
  --set admin.defaultGatewayTokensValue=my-super-secret-token-xyz
``` 

### reShapr proxy

```sh
helm pull oci://quay.io/reshapr/reshapr-helm-charts/reshapr-proxy --version 0.0.2

helm install reshapr-proxy oci://quay.io/reshapr/reshapr-helm-charts/reshapr-proxy --version 0.0.2 \
  --create-namespace --namespace reshapr-proxies \
  --set gateway.idPrefix=acme \
  --set gateway.labels='env=dev;team=reshapr' \
  --set gateway.fqdns=mcp.acme.loc \
  --set ingress.enabled=true \
  --set 'ingress.hosts[0].host=mcp.acme.loc' \
  --set gateway.controlPlane.host=reshapr-control-plane-ctrl.reshapr-system \
  --set gateway.controlPlane.port=5555 \
  --set gateway.controlPlane.token=reshapr-my-super-secret-token-xyz
```