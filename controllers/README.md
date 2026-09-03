# Reshapr Controllers Helm Chart

This Helm chart deploys the **reShapr Controllers** on a Kubernetes cluster. It bundles two
independent components that can be installed separately or together:

- **Operator** — reconciles reShapr Custom Resources (`Service`, `Exposition`, `GatewayGroup`,
  `ConfigurationPlan`, `CustomTools`, `SecretSource`, `Resource`).
- **Admission Controller** — a mutating admission webhook that injects the reShapr proxy as a
  sidecar container into annotated Pods.

It corresponds to the reshapr-controllers **0.0.1** release.

## Components

| Component            | Kind(s) created                                              | Enabled by |
|----------------------|-------------------------------------------------------------|------------|
| Operator             | Deployment, ServiceAccount, ClusterRole(s), ClusterRoleBinding(s) | `operator.enabled` |
| Admission Controller | Deployment, Service, ServiceAccount, ClusterRole, ClusterRoleBinding, MutatingWebhookConfiguration (+ TLS resources depending on the provider) | `admissionController.enabled` |

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- A running **reShapr control plane** reachable from within the cluster
- [cert-manager](https://cert-manager.io/) — only when deploying the Admission Controller with
  the default `cert-manager` certificate provider (see [TLS for the Admission Controller](#tls-for-the-admission-controller)
  for alternatives)

## Installing the Chart

By default, **both** the Operator and the Admission Controller are enabled.

### Both components (default)

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace
```

### Operator only

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace \
  --set admissionController.enabled=false
```

### Admission Controller only

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace \
  --set operator.enabled=false
```

### Development / Production values

```bash
# Development (nightly images, pullPolicy Always)
helm install reshapr-controllers ./controllers -n reshapr-system --create-namespace -f values-dev.yaml

# Production (resource limits, HA admission webhook, anti-affinity)
helm install reshapr-controllers ./controllers -n reshapr-system --create-namespace -f values-production.yaml
```

## Custom Resource Definitions (CRDs)

Helm installs the CRDs located in the `crds/` folder before any other resource. To skip CRD
installation on upgrade, use the standard flag:

```bash
helm install reshapr-controllers ./controllers -n reshapr-system --skip-crds
```

To refresh the CRDs from the upstream `reshapr-controllers` repository:

```bash
./controllers/sync-crds.sh            # syncs from main
REF=0.0.1 ./controllers/sync-crds.sh  # syncs from a specific tag/branch
```

> [!WARNING]
> Uninstalling the chart does **not** remove CRDs (Helm never deletes CRDs). Deleting them
> manually removes every custom resource of these kinds across all namespaces.

## Operator

The operator authenticates to the control plane using a **projected ServiceAccount token**
mounted at `/var/run/secrets/reshapr/serviceaccount`. Before it can reconcile resources, its
ServiceAccount must be registered as a trusted client on the control plane:

```bash
export RESHAPR_ADMIN_API_KEY='<admin-api-key>'

reshapr admin --server https://reshapr.acme.loc \
  service-account create reshapr-system-operator \
  --k8s-subject reshapr-system:reshapr-controllers-operator \
  --allowed-organizations '["*"]' \
  --validity-days 90
```

The token audience is fixed to `https://app.reshapr.io` to match the audience expected by the
control plane (`KubernetesTokenVerifier`); the token expiry is configurable via
`operator.controlPlane.tokenExpirationSeconds`.

### RBAC for SecretSource reads

The operator ships **two** ClusterRole/ClusterRoleBinding pairs:

- `…-operator` — full access to the `reshapr.io` API group (always required).
- `…-operator-secret-reader` — `get`/`list`/`watch` on core `secrets`, used **only** by the
  `SecretSource` reconciler.

To scope down or disable the SecretSource feature, set
`operator.rbac.createSecretReader=false` and, if needed, bind the `…-operator-secret-reader`
ClusterRole with your own namespaced RoleBindings.

## TLS for the Admission Controller

The webhook must be served over HTTPS with a certificate trusted by the Kubernetes API server.
The chart supports three providers via `admissionController.certificate.provider`, mirroring the
[Alternatives to cert-manager](https://github.com/reshaprio/reshapr-controllers/blob/main/documentation/admission-controller.md#alternatives-to-cert-manager)
documentation.

| Situation                                                        | Provider       |
|------------------------------------------------------------------|----------------|
| cert-manager is available (or you can install it)                | `cert-manager` (default) |
| OpenShift / OKD                                                  | `openshift`    |
| Corporate PKI (Bring-Your-Own) or Kubernetes CSR API             | `existing`     |

### `cert-manager` (default)

The chart creates a self-signed `Issuer`, a `Certificate` (with a PKCS12 keystore), and the
keystore-password `Secret`. cert-manager injects the CA bundle into the
`MutatingWebhookConfiguration` through the `cert-manager.io/inject-ca-from` annotation.

```yaml
admissionController:
  certificate:
    provider: cert-manager
    certManager:
      duration: 2160h
      renewBefore: 360h
      # keystorePassword: ""       # auto-generated & preserved across upgrades when empty
      # issuerRef: {}              # reuse an existing Issuer/ClusterIssuer instead of the self-signed one
```

To reuse an existing issuer instead of the chart's self-signed one:

```yaml
admissionController:
  certificate:
    certManager:
      issuerRef:
        name: my-cluster-issuer
        kind: ClusterIssuer
```

### `openshift` — service-ca-operator

On OpenShift/OKD, the built-in Service CA Operator provisions the serving certificate and
injects the CA bundle. The chart annotates the Service
(`service.beta.openshift.io/serving-cert-secret-name`) and the webhook
(`service.beta.openshift.io/inject-cabundle`). Because the generated Secret is PEM-formatted,
the webhook is automatically configured to serve HTTPS from `tls.crt` / `tls.key`.

```yaml
admissionController:
  certificate:
    provider: openshift
```

### `existing` — Bring-Your-Own certificate / CSR API

Provide the certificate yourself (corporate PKI, HashiCorp Vault, AWS Private CA, the
Kubernetes CertificateSigningRequest API, …). The chart creates no TLS resources; it only
mounts your Secret and sets the webhook `caBundle`.

**PKCS12 keystore** (default):

```bash
openssl pkcs12 -export -inkey tls.key -in tls.crt \
  -out keystore.p12 -password pass:$KEYSTORE_PASSWORD

kubectl -n reshapr-system create secret generic reshapr-admission-controller-tls-secret \
  --from-file=keystore.p12=./keystore.p12
kubectl -n reshapr-system create secret generic reshapr-admission-controller-tls-pass \
  --from-literal=password=$KEYSTORE_PASSWORD
```

```yaml
admissionController:
  certificate:
    provider: existing
    existing:
      type: pkcs12
      secretName: reshapr-admission-controller-tls-secret
      passwordSecretName: reshapr-admission-controller-tls-pass
      passwordKey: password
    caBundle: <base64-encoded PEM of the issuing CA>
```

**PEM certificate**:

```yaml
admissionController:
  certificate:
    provider: existing
    existing:
      type: pem
      secretName: my-tls-secret   # must contain tls.crt and tls.key
    caBundle: <base64-encoded PEM of the issuing CA>
```

> [!TIP]
> When the CA bundle is injected out-of-band (e.g. by an external controller), leave
> `caBundle` empty. Companion tools such as [External Secrets Operator](https://external-secrets.io/)
> (to sync the Secret) and [Reloader](https://github.com/stakater/Reloader) (to restart the
> Pod on rotation) pair well with this provider.

## Webhook behaviour

The `MutatingWebhookConfiguration` intercepts only Pod `CREATE` operations and **excludes system
namespaces** (the release namespace plus `kube-system`, `kube-node-lease`, `kube-public` by
default) to avoid a self-deadlock. It is configured to **fail open** (`failurePolicy: Ignore`)
so a failing webhook never blocks workload scheduling. These are tunable:

```yaml
admissionController:
  webhook:
    path: /mutate
    timeoutSeconds: 5
    failurePolicy: Ignore          # or Fail
    excludedNamespaces:
      - kube-system
      - kube-node-lease
      - kube-public
```

## OpenShift Compatibility

The `podSecurityContext` and `securityContext` are empty by default so OpenShift's
`restricted-v2` SCC can inject the correct UIDs. Combine with `certificate.provider=openshift`
for a fully OpenShift-native install.

## Parameters

### Global

| Parameter            | Description                              | Default |
|----------------------|------------------------------------------|---------|
| `imagePullSecrets`   | Image pull secrets for private registries | `[]`    |
| `nameOverride`       | Override the chart name                  | `""`    |
| `fullnameOverride`   | Override the fully qualified name        | `""`    |
| `podSecurityContext` | Pod security context (empty for OpenShift) | `{}`  |
| `securityContext`    | Container security context (empty for OpenShift) | `{}` |

### Operator

| Parameter                                   | Description                                        | Default |
|---------------------------------------------|----------------------------------------------------|---------|
| `operator.enabled`                          | Enable the operator                                | `true`  |
| `operator.replicaCount`                     | Number of replicas                                 | `1`     |
| `operator.image.repository`                 | Image repository                                   | `registry.reshapr.io/reshapr/reshapr-operator` |
| `operator.image.tag`                        | Image tag (defaults to chart appVersion when empty)| `""`    |
| `operator.image.pullPolicy`                 | Image pull policy                                  | `IfNotPresent` |
| `operator.extraEnv`                         | Extra environment variables                        | `[]`    |
| `operator.controlPlane.tokenExpirationSeconds` | Expiry of the projected SA token (seconds)      | `3600`  |
| `operator.rbac.create`                      | Create the operator ClusterRole/Binding            | `true`  |
| `operator.rbac.createSecretReader`          | Create the SecretSource secret-reader RBAC         | `true`  |
| `operator.serviceAccount.create`            | Create the operator ServiceAccount                 | `true`  |
| `operator.serviceAccount.name`              | ServiceAccount name (generated when empty)         | `""`    |
| `operator.serviceAccount.annotations`       | ServiceAccount annotations                         | `{}`    |
| `operator.resources`                        | Resource requests/limits                           | `{}`    |
| `operator.nodeSelector` / `tolerations` / `affinity` | Scheduling controls                       | `{}` / `[]` / `{}` |
| `operator.podAnnotations`                   | Pod annotations                                    | `{}`    |

### Admission Controller

| Parameter                                          | Description                                   | Default |
|----------------------------------------------------|-----------------------------------------------|---------|
| `admissionController.enabled`                      | Enable the admission webhook                  | `true`  |
| `admissionController.replicaCount`                 | Number of replicas                            | `1`     |
| `admissionController.image.repository`             | Image repository                              | `registry.reshapr.io/reshapr/reshapr-admission` |
| `admissionController.image.tag`                    | Image tag (defaults to chart appVersion when empty) | `""` |
| `admissionController.image.pullPolicy`             | Image pull policy                             | `IfNotPresent` |
| `admissionController.service.type`                 | Service type                                  | `ClusterIP` |
| `admissionController.service.httpPort`             | Service HTTP port                             | `80`    |
| `admissionController.service.httpsPort`            | Service HTTPS port (called by the API server) | `443`   |
| `admissionController.httpContainerPort`            | Container HTTP port                           | `8080`  |
| `admissionController.httpsContainerPort`           | Container HTTPS port                          | `443`   |
| `admissionController.webhook.path`                 | Webhook path                                  | `/mutate` |
| `admissionController.webhook.timeoutSeconds`       | Webhook timeout                               | `5`     |
| `admissionController.webhook.failurePolicy`        | `Ignore` (fail open) or `Fail`                | `Ignore` |
| `admissionController.webhook.excludedNamespaces`   | Extra namespaces excluded from interception   | `[kube-system, kube-node-lease, kube-public]` |
| `admissionController.certificate.provider`         | `cert-manager`, `openshift`, or `existing`    | `cert-manager` |
| `admissionController.certificate.certManager.duration`   | Certificate validity                    | `2160h` |
| `admissionController.certificate.certManager.renewBefore`| Renew before expiry                     | `360h`  |
| `admissionController.certificate.certManager.keystorePassword` | PKCS12 password (auto-generated when empty) | `""` |
| `admissionController.certificate.certManager.issuerRef`  | Reuse an existing Issuer/ClusterIssuer  | `{}`    |
| `admissionController.certificate.existing.type`    | `pkcs12` or `pem`                             | `pkcs12` |
| `admissionController.certificate.existing.secretName` | TLS Secret name                            | `reshapr-admission-controller-tls-secret` |
| `admissionController.certificate.existing.passwordSecretName` | Keystore password Secret (pkcs12)   | `reshapr-admission-controller-tls-pass` |
| `admissionController.certificate.existing.passwordKey` | Key of the password inside the Secret     | `password` |
| `admissionController.certificate.caBundle`         | Base64 PEM CA bundle for the webhook (`existing`) | `""` |
| `admissionController.serviceAccount.create`        | Create the admission ServiceAccount           | `true`  |
| `admissionController.serviceAccount.name`          | ServiceAccount name (generated when empty)    | `""`    |
| `admissionController.serviceAccount.annotations`   | ServiceAccount annotations                    | `{}`    |
| `admissionController.resources`                    | Resource requests/limits                      | `{}`    |
| `admissionController.nodeSelector` / `tolerations` / `affinity` | Scheduling controls              | `{}` / `[]` / `{}` |
| `admissionController.podAnnotations`               | Pod annotations                               | `{}`    |

## Upgrading

```bash
helm upgrade reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --reuse-values
```

## Uninstalling

```bash
helm uninstall reshapr-controllers --namespace reshapr-system
```

CRDs are intentionally left in place. Remove them manually if you really intend to delete every
reShapr custom resource.

## Troubleshooting

```bash
# Pods
kubectl get pods -n reshapr-system -l app.kubernetes.io/instance=reshapr-controllers

# Operator logs
kubectl logs -n reshapr-system -l app.kubernetes.io/component=operator -f

# Admission webhook logs
kubectl logs -n reshapr-system -l app.kubernetes.io/component=admission -f

# Webhook registration & CA bundle
kubectl get mutatingwebhookconfigurations reshapr-controllers-mutating-webhook -o yaml

# cert-manager certificate readiness
kubectl get certificate -n reshapr-system
```

See [`COMMANDS.md`](./COMMANDS.md) for more day-2 commands.
