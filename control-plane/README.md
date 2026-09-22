# Reshapr Control Plane Helm Chart

This Helm chart deploys the Reshapr Control Plane components on a Kubernetes cluster.

## Components

This chart installs the following components:

- **reshapr-ctrl**: The main control plane API server
- **PostgreSQL**: Database for the control plane

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- A PostgreSQL database (if not using the embedded one)

## PostgreSQL Version

The embedded PostgreSQL uses version **17.6.0** (via Bitnami chart 16.7.27), which matches the version used in development.

## Installing the Chart

### With External PostgreSQL (Recommended for Production)

```bash
helm install reshapr-control-plane ./control-plane \
  --namespace reshapr-system \
  --create-namespace \
  --set postgresql.enabled=false \
  --set externalDatabase.host=postgresql.example.com \
  --set externalDatabase.password=<your-password> \
  --set apiKey.value=<your-api-key>
```

### With Embedded PostgreSQL (Development/Testing)

```bash
# First, add the Bitnami repository for PostgreSQL dependency
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Update chart dependencies
helm dependency update ./control-plane

# Install the chart
helm install reshapr-control-plane ./control-plane \
  --namespace reshapr-system \
  --create-namespace \
  --set postgresql.enabled=true \
  --set postgresql.auth.password=<postgres-password> \
  --set apiKey.value=<your-api-key>
```

### With Ingress

```bash
helm install reshapr-control-plane ./control-plane \
  --namespace reshapr-system \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.ctrl.host=app.reshapr.example.com \
  --set postgresql.enabled=false \
  --set externalDatabase.host=postgresql.example.com \
  --set externalDatabase.password=<your-password> \
  --set apiKey.value=<your-api-key>
```

## Configuration

The following table lists the configurable parameters of the Reshapr Control Plane chart and their default values.

### Global Parameters

| Parameter          | Description                           | Default  |
|--------------------|---------------------------------------|----------|
| `imagePullSecrets` | Global image pull secrets             | `[]`     |
| `nameOverride`     | Override the name of the chart        | `""`     |
| `fullnameOverride` | Override the full name of the release | `""`     |

### reshapr-ctrl Parameters

| Parameter                          | Description                  | Default                         |
|------------------------------------|------------------------------|---------------------------------|
| `ctrl.enabled`                     | Enable reshapr-ctrl component | `true`                          |
| `ctrl.replicaCount`                | Number of replicas           | `1`                             |
| `ctrl.image.repository`            | Image repository             | `registry.reshapr.io/reshapr/reshapr-ctrl` |
| `ctrl.image.tag`                   | Image tag                    | `nightly`                       |
| `ctrl.image.pullPolicy`            | Image pull policy            | `IfNotPresent`                  |
| `ctrl.serviceAccount.create`       | Create service account       | `true`                          |
| `ctrl.serviceAccount.name`         | Service account name         | `""`                            |
| `ctrl.service.type`                | Service type                 | `ClusterIP`                     |
| `ctrl.service.port`                | Service port                 | `5555`                          |
| `ctrl.resources.limits.cpu`        | CPU limit                    | `1000m`                         |
| `ctrl.resources.limits.memory`     | Memory limit                 | `512Mi`                         |
| `ctrl.resources.requests.cpu`      | CPU request                  | `100m`                          |
| `ctrl.resources.requests.memory`   | Memory request               | `256Mi`                         |
| `ctrl.nodeSelector`                | Node selector                | `{}`                            |
| `ctrl.tolerations`                 | Tolerations                  | `[]`                            |
| `ctrl.affinity`                    | Affinity rules               | `{}`                            |
| `ctrl.podDisruptionBudget.enabled` | Enable PDB                   | `false`                         |

### PostgreSQL Parameters

| Parameter                                | Description                | Default  |
|------------------------------------------|----------------------------|----------|
| `postgresql.enabled`                     | Enable embedded PostgreSQL | `false`  |
| `postgresql.auth.username`               | Database username          | `reshapr` |
| `postgresql.auth.password`               | Database password          | `""`     |
| `postgresql.auth.database`               | Database name              | `reshapr` |
| `postgresql.primary.persistence.enabled` | Enable persistence         | `true`   |
| `postgresql.primary.persistence.size`    | Persistence volume size    | `8Gi`    |

### External Database Parameters

| Parameter                         | Description                              | Default  |
|-----------------------------------|------------------------------------------|----------|
| `externalDatabase.host`           | Database host                            | `""`     |
| `externalDatabase.port`           | Database port                            | `5432`   |
| `externalDatabase.database`       | Database name                            | `reshapr` |
| `externalDatabase.username`       | Database username                        | `reshapr` |
| `externalDatabase.password`       | Database password                        | `""`     |
| `externalDatabase.existingSecret` | Existing secret for database credentials | `""`     |

### Admin Credentials Parameters

| Parameter                         | Description                                 | Default   |
|-----------------------------------|---------------------------------------------|-----------|
| `admin.nameValue`                 | Admin account username                      | `""`      |
| `admin.passwordValue`             | Admin account password                      | `""`      |
| `admin.emailValue`                | Admin account email                         | `""`      |
| `admin.defaultGatewayTokensValue` | CSV list of tokens for reshapr org gateways | `""`      |
| `admin.existingSecret`            | Existing secret for Admin credentials       | `""`      |
| `admin.nameKey`                   | Key in the secret for Admin username        | `""`      |
| `admin.passwordKey`               | Key in the secret for Admin password        | `""`      |
| `admin.emailKey`                  | Key in the secret for Admin email           | `""`      |
| `admin.defaultGatewayTokensKey`   | Key in the secret for defaultGatewayTokens  | `""`      |
| `admin.defaultGatewayLabels`      | Default gateway group labels (semi-colon separated `key=value` pairs) | `""`      |
| `admin.defaultGatewayLabels`.     | Default gateway group labels (semi-colon separated key=value pairs)  | `""`      |

### Authentication Parameters

| Parameter                                | Description                                               | Default         |
|------------------------------------------|-----------------------------------------------------------|-----------------|
| `authentication.idp.enabled`             | Enable external OIDC ID provider authentication           | `false`         |
| `authentication.idp.url`                 | OIDC ID provider authentication screen URL                | `""`            |
| `authentication.idp.tokenUrl`            | OIDC ID provider token URL to exchange authorization code | `""`            |
| `authentication.idp.clientId`            | OIDC ID provider client ID (used when existingSecret is not set) | `""`     |
| `authentication.idp.clientSecret`        | OIDC ID provider client secret (used when existingSecret is not set, optional) | `""` |
| `authentication.idp.existingSecret`      | Existing secret for IDP client credentials                | `""`            |
| `authentication.idp.clientIdKey`         | Key in the existing secret for client ID                  | `"client-id"`   |
| `authentication.idp.clientSecretKey`     | Key in the existing secret for client secret              | `"client-secret"` |
| `authentication.idp.scopes`              | Additional OIDC scopes to request (comma-separated list, e.g. `my-scope-1,my-scope-2`) | `""` |
| `authentication.idp.allowedRedirectUris` | Exact final redirect URIs allowed for browser clients | `[]` |
| `authentication.idp.allowCliLoopbackRedirect` | Allow CLI callbacks on HTTP loopback addresses using ports `5556-5599` | `true` |
| `authentication.idp.guardAccess.group`   | Restrict access to a specific IDP group (standard JWT `groups` claim) | `""`   |
| `authentication.idp.guardAccess.claim`   | Restrict access based on a claim `name=value` expression  | `""`            |
| `authentication.idp.defaultOrganization.claim`       | Resolve default organization from a specific JWT claim | `""`      |
| `authentication.idp.defaultOrganization.groupPrefix` | Resolve default organization from a JWT group prefix (e.g. `reshapr-org`) | `""` |
| `authentication.idp.defaultOrganization.value`       | Use a specific default organization value | `""`                     |

When the embedded Web UI is enabled and `reshapr-web-ui.publicUrl` is set, the chart automatically adds
`<publicUrl>/api/auth/callback/oidc` to the control plane's allowed redirect URIs. Explicit entries are
preserved and duplicates are removed:

```yaml
authentication:
  idp:
    enabled: true
    allowedRedirectUris:
      - https://another-client.example.com/oidc/callback

reshapr-web-ui:
  enabled: true
  publicUrl: https://app.reshapr.example.com
```

This configuration renders both callbacks in `RESHAPR_AUTHENTICATION_IDP_ALLOWED_REDIRECT_URIS`. Set
`authentication.idp.allowCliLoopbackRedirect` to `false` when CLI browser login is not required.

### API Key Parameters

| Parameter               | Description                   | Default   |
|-------------------------|-------------------------------|-----------|
| `apiKey.value`          | API key value                 | `""`      |
| `apiKey.existingSecret` | Existing secret for API key   | `""`      |
| `apiKey.key`            | Key in the secret for API key | `api-key` |

### Encryption Key Parameters

| Parameter                              | Description                                                                  | Default             |
|----------------------------------------|------------------------------------------------------------------------------|---------------------|
| `encryptionKey.activeKeyId`            | Key identifier used for new encryption operations                            | `v1`                |
| `encryptionKey.keys.<kid>.value`       | Base64-encoded 32-byte AES-256 key (when the chart creates the Secret)       | `""`                |
| `encryptionKey.keys.<kid>.key`         | Kubernetes Secret data key containing this AES-256 key                       | `encryption-key-v1` |
| `encryptionKey.value`                  | Legacy AES/ECB key retained while existing data is migrated (must be 16, 24 or 32 characters long) | `""` |
| `encryptionKey.existingSecret`         | Existing Secret containing every AES-256 key and the legacy key              | `""`                |
| `encryptionKey.key`                    | Kubernetes Secret data key containing the legacy AES/ECB key                 | `encryption-key`    |

Each key identifier (`kid`) becomes the prefix of newly encrypted values and must start with a lowercase
letter and contain only lowercase letters and digits. For production, create the Secret outside Helm:

```bash
kubectl create secret generic reshapr-encryption-key-secret \
  --from-literal=encryption-key-v1="$(openssl rand -base64 32)" \
  --from-literal=encryption-key='<current-legacy-key>' \
  --namespace reshapr-system
```

Then reference all keys that must remain available for decryption:

```yaml
encryptionKey:
  existingSecret: reshapr-encryption-key-secret
  activeKeyId: v2
  keys:
    v1:
      key: encryption-key-v1
    v2:
      key: encryption-key-v2
  key: encryption-key
```

During rotation, add the new AES-256 key to the Secret and `keys`, then switch `activeKeyId`. Keep prior
AES keys until no value uses their prefix, and keep the legacy key until all unprefixed values are migrated.

### JWT Keys Parameters

| Parameter                     | Description                                                                | Default            |
|-------------------------------|----------------------------------------------------------------------------|--------------------|
| `jwtKeys.existingSecret`      | Existing secret for both private and public keys                           | `""`               |
| `jwtKeys.privateKey.value`    | Private key value for signing JWT tokens (should be overridden in production) | `""`            |
| `jwtKeys.privateKey.key`      | Key in the existing secret for private key                                 | `private-key.pem`  |
| `jwtKeys.publicKey.value`     | Public key value for verifying JWT tokens (should be overridden in production) | `""`           |
| `jwtKeys.publicKey.key`       | Key in the existing secret for public key                                  | `public-key.pem`   |

### Ingress Parameters

| Parameter            | Description        | Default  |
|----------------------|--------------------|----------|
| `ingress.enabled`    | Enable ingress     | `false`  |
| `ingress.className`  | Ingress class name | `""`     |
| `ingress.ctrl.host`  | Hostname for ctrl  | `""`     |
| `ingress.tls`        | TLS configuration  | `[]`     |

## Examples

### High Availability Setup

```yaml
ctrl:
  replicaCount: 3
  podDisruptionBudget:
    enabled: true
    minAvailable: 2
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app.kubernetes.io/component
                  operator: In
                  values:
                    - ctrl
            topologyKey: kubernetes.io/hostname

postgresql:
  enabled: false

externalDatabase:
  host: postgresql-ha.database.svc.cluster.local
  existingSecret: reshapr-db-credentials
```

### With Node Selectors and Tolerations

```yaml
ctrl:
  nodeSelector:
    node-role.kubernetes.io/control-plane: "true"
  tolerations:
    - key: "node-role.kubernetes.io/control-plane"
      operator: "Exists"
      effect: "NoSchedule"
```

## Upgrading

```bash
helm upgrade reshapr-control-plane ./charts/control-plane \
  --namespace reshapr-system \
  --reuse-values
```

## Uninstalling

```bash
helm uninstall reshapr-control-plane --namespace reshapr-system
```

## Security Considerations

1. **Always set strong passwords** for database passwords
2. **Generate a secure API key** for `apiKey.value` (at least 128 characters)
3. **Use existing secrets** in production instead of passing passwords as values
4. **Enable TLS** for ingress in production
5. **Use external database** with proper backup and HA setup in production
6. **Enable Pod Security Standards** in your namespace
7. **Review and adjust resource limits** based on your workload

## Troubleshooting

### Check pod status

```bash
kubectl get pods -n reshapr-system -l app.kubernetes.io/instance=reshapr-control-plane
```

### View logs

```bash
# reshapr-ctrl logs
kubectl logs -n reshapr-system -l app.kubernetes.io/component=ctrl
```

### Check database connectivity

```bash
kubectl exec -n reshapr-system -it <ctrl-pod-name> -- sh -c 'echo "SELECT 1" | psql $QUARKUS_DATASOURCE_JDBC_URL -U $QUARKUS_DATASOURCE_USERNAME'
```

## Contributing

Please see the main Reshapr repository for contribution guidelines.

## License

See the main Reshapr repository for license information.
