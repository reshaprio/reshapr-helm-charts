# reShapr Helm Charts

Helm Charts for installing reShapr components on Kubernetes

[![Helm](https://img.shields.io/badge/dynamic/json?color=0F1689&logo=helm&style=for-the-badge&label=Helm&query=tags[1].name&url=https://quay.io/api/v1/repository/reshapr/reshapr-helm-charts/reshapr-control-plane/tag/?limit=10&page=1&onlyActiveTags=true)](https://quay.io/repository/reshapr/reshapr-helm-charts/reshapr-control-plane?tab=tags)
[![License](https://img.shields.io/github/license/microcks/microcks-testcontainers-java?style=for-the-badge&logo=apache)](https://www.apache.org/licenses/LICENSE-2.0)
[![Project Chat](https://img.shields.io/badge/discord-reshapr-pink.svg?color=7289da&style=for-the-badge&logo=discord)](https://discord.gg/KyDUdam34h)
[![GitHub stars](https://img.shields.io/github/stars/reshaprio/reshapr-helm-charts?style=for-the-badge&logo=github&color=ffad05)](https://github.com/reshaprio/reshapr-helm-charts)

## Build Status

Latest released version is `0.0.5`.

Current development version is `0.0.6`.

## How to use them?

This repository contains two Helm charts:

* The `reshapr-control-plane` Helm chart is dedicated to the installation of the reShapr control plane. It is distributed as an OCI artifact on https://quay.io/repository/reshapr/reshapr-helm-charts/reshapr-control-plane

* The `reshapr-proxy` Helm chart is dedicated to the installation of the reShapr proxy. It is distributed as an OCI artifact on https://quay.io/repository/reshapr/reshapr-helm-charts/reshapr-proxy

* The `reshapr-ui` Helm chart is dedicated to the installation of the reShapr control UI. It is distributed as an OCI artifact on https://quay.io/repository/reshapr/reshapr-helm-charts/reshapr-ui

### reShapr control plane

```sh
helm pull oci://quay.io/reshapr/reshapr-helm-charts/reshapr-control-plane --version 0.0.5

helm install reshapr-control-plane oci://quay.io/reshapr/reshapr-helm-charts/reshapr-control-plane --version 0.0.5 \
  --create-namespace --namespace reshapr-system \
  --set postgresql.enabled=true \
  --set postgresql.auth.password=admin \
  --set apiKey.value=dev-api-key-change-me-in-production \
  --set encryptionKey.value=dev-encryption-key-change-me-in-production \
  --set admin.nameValue=admin \
  --set admin.passwordValue=password \
  --set admin.emailValue=reshapr@example.com \
  --set admin.defaultGatewayTokensValue=my-super-secret-token-xyz \
  --set ingress.enabled=true \
  --set ingress.ctrl.host=reshapr.acme.loc
``` 

### reShapr proxy

```sh
helm pull oci://quay.io/reshapr/reshapr-helm-charts/reshapr-proxy --version 0.0.5

helm install reshapr-proxy oci://quay.io/reshapr/reshapr-helm-charts/reshapr-proxy --version 0.0.5 \
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

### reShapr ui

For this one, a TLS ingress is mandatory if you choose to enable TLS. We're using a CertManager ClusterIssuer in example below:

```sh
helm pull oci://quay.io/reshapr/reshapr-helm-charts/reshapr-ui --version 0.0.6

helm install reshapr-ui oci://quay.io/reshapr/reshapr-helm-charts/reshapr-ui --version 0.0.6 \
  --namespace reshapr-system \
  --create-namespace \
  --set apiKey.value=dev-api-key-change-me-in-production \
  --set publicUrl=https://reshapr-ui.acme.loc \
  --set ingress.enabled=true \
  --set ingress.annotations."cert\-manager\.io\/cluster\-issuer"=cert-cluster-issuer \
  --set 'ingress.hosts[0].host=reshapr-ui.acme.loc' \
  --set 'ingress.tls[0].hosts[0]=reshapr-ui.acme.loc' \
  --set 'ingress.tls[0].secretName=reshapr-web-ui-tls'
```