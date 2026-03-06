# Reshapr Control Plane Helm Chart

This Helm chart deploys the Reshapr Control Plane components on a Kubernetes cluster.

## Components

This chart installs the following components:

- **reshapr-ctrl**: The main control plane API server
- **PostgreSQL** (optional): Database for both components

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
  --set authz.admin.password=<keycloak-admin-password> \
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
| `ctrl.image.repository`            | Image repository             | `quay.io/reshapr/reshapr-ctrl` |
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

### API Key Parameters

| Parameter               | Description                   | Default   |
|-------------------------|-------------------------------|-----------|
| `apiKey.value`          | API key value                 | `""`      |
| `apiKey.existingSecret` | Existing secret for API key   | `""`      |
| `apiKey.key`            | Key in the secret for API key | `api-key` |

### Ingress Parameters

| Parameter            | Description        | Default  |
|----------------------|--------------------|----------|
| `ingress.enabled`    | Enable ingress     | `false`  |
| `ingress.className`  | Ingress class name | `""`     |
| `ingress.ctrl.host`  | Hostname for ctrl  | `""`     |
| `ingress.authz.host` | Hostname for authz | `""`     |
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

authz:
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

# reshapr-authz logs
kubectl logs -n reshapr-system -l app.kubernetes.io/component=authz
```

### Check database connectivity

```bash
kubectl exec -n reshapr-system -it <ctrl-pod-name> -- sh -c 'echo "SELECT 1" | psql $QUARKUS_DATASOURCE_JDBC_URL -U $QUARKUS_DATASOURCE_USERNAME'
```

## Contributing

Please see the main Reshapr repository for contribution guidelines.

## License

See the main Reshapr repository for license information.
