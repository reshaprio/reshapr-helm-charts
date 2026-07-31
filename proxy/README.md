# Reshapr Gateway Helm Chart

This Helm chart deploys the Reshapr Proxy component (Data Plane) on a Kubernetes cluster.

## Components

This chart installs the **reshapr-proxy** component, which serves as the data plane for MCP (Model Context Protocol) operations.

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- Reshapr Control Plane deployed (reshapr-ctrl)
- Control plane token/API key

## Installing the Chart

### Basic Installation

```bash
helm install reshapr-proxy ./proxy \
  --namespace reshapr-proxies \
  --create-namespace \
  --set gateway.controlPlane.token=<your-control-plane-token> \
  --set gateway.fqdns=<your-gateway-fqdns>
```

### Development Installation

```bash
helm install reshapr-proxy ./proxy \
  --namespace reshapr-proxies \
  --create-namespace \
  -f values-dev.yaml
```

### Production Installation with External Secret

```bash
# Create the token secret first
kubectl create secret generic reshapr-proxy-token \
  --from-literal=token='your-control-plane-token' \
  --namespace reshapr-proxies

# Install the chart
helm install reshapr-proxy ./proxy \
  --namespace reshapr-proxies \
  --create-namespace \
  -f values-production.yaml \
  --set gateway.fqdns=mcp.reshapr.example.com \
  --set ingress.hosts[0].host=mcp.reshapr.example.com
```

## Configuration

The following table lists the configurable parameters of the Reshapr Gateway chart and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `imagePullSecrets` | Global image pull secrets | `[]` |
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the full name of the release | `""` |

### Proxy Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `registry.reshapr.io/resphar/reshapr-proxy` |
| `image.tag` | Image tag | `nightly` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.name` | Service account name | `""` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `7777` |
| `resources.limits.cpu` | CPU limit | `1000m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `256Mi` |

### Gateway Specific Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `gateway.idPrefix` | Gateway ID prefix (combined with pod name) | `""` |
| `gateway.fqdns` | Gateway FQDNs (comma-separated) | `""` |
| `gateway.labels` | Gateway labels (semi-colon -separated key=value) | `env=dev;team=reshapr` |
| `gateway.controlPlane.host` | Control plane host | `reshapr-control-plane-ctrl` |
| `gateway.controlPlane.port` | Control plane port | `5555` |
| `gateway.controlPlane.token` | Control plane token | `""` |
| `gateway.controlPlane.existingSecret` | Existing secret for token | `""` |
| `gateway.controlPlane.tokenKey` | Key in secret for token | `token` |

### Autoscaling Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU % | `80` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target Memory % | `null` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | `[]` |
| `ingress.tls` | TLS configuration | `[]` |

### Monitoring Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceMonitor.enabled` | Enable ServiceMonitor for Prometheus | `false` |
| `serviceMonitor.interval` | Scrape interval | `30s` |
| `serviceMonitor.scrapeTimeout` | Scrape timeout | `10s` |

### Clustering Parameters (Infinispan embedded)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `clustering.enabled` | Enable replicated MCP state across pods (JGroups DNS_PING) | `true` |
| `clustering.jgroups.port` | JGroups TCP bind port | `7778` |
| `clustering.jgroups.fdPort` | JGroups FD_SOCK2 failure-detection port | `57778` |
| `clustering.networkPolicy.enabled` | Create a NetworkPolicy for JGroups pod-to-pod traffic | `false` |
| `clustering.encryption.existingSecret` | Use your own Secret (skip auto-generation) | `""` |
| `clustering.encryption.storePasswordKey` | Key in the Secret for the keystore store password | `store-password` |
| `clustering.encryption.keyPasswordKey` | Key in the Secret for the keystore key password | `key-password` |
| `clustering.encryption.keystoreMountPath` | Mount path for the keystore | `/etc/reshapr/keystore` |
| `clustering.encryption.keystoreFile` | Keystore filename (key name inside the Secret) | `reshapr-cluster.jceks` |
| `clustering.encryption.alias` | Key alias inside the JCEKS keystore | `reshapr-cluster` |
| `clustering.encryption.kubectlImage` | Image for the keystore generation Job | `bitnami/kubectl:latest` |

## Infinispan Clustering

When `clustering.enabled=true` (the default), the proxy pods form a replicated Infinispan cluster using JGroups DNS_PING over a headless Service. MCP session state (`session-store`, `elicitation-store`, `user-secret-store`) is replicated across all pods, ensuring resilience during rolling updates and pod failures.

The JGroups transport is always encrypted with **SYM_ENCRYPT** (AES-256). A shared JCEKS keystore is required by all pods to form the cluster.

### Default behavior (auto-generated keystore)

On initial `helm install`, a **pre-install hook Job** automatically:
1. Generates a JCEKS keystore containing an AES-256 secret key
2. Stores it in a Kubernetes Secret (annotated with `helm.sh/resource-policy: keep`)

On subsequent `helm upgrade`, the Job does **not** re-run. The previously generated Secret is reused, so new pods from a rolling update can join the existing cluster without interruption.

### Bring Your Own Key (BYOK)

If you want to manage the keystore yourself (e.g., for compliance, key rotation, or multi-cluster setups), you can provide your own Secret.

**Step 1 — Generate the JCEKS keystore:**

```bash
keytool -genseckey \
  -alias reshapr-cluster \
  -keyalg AES -keysize 256 \
  -storetype JCEKS \
  -keystore reshapr-cluster.jceks \
  -storepass <your-store-password> \
  -keypass <your-key-password> \
  -noprompt
```

**Step 2 — Create the Kubernetes Secret:**

```bash
kubectl create secret generic my-cluster-keystore \
  --namespace reshapr-proxies \
  --from-file=reshapr-cluster.jceks=reshapr-cluster.jceks \
  --from-literal=store-password='<your-store-password>' \
  --from-literal=key-password='<your-key-password>'
```

**Step 3 — Reference it in your values:**

```yaml
clustering:
  encryption:
    existingSecret: "my-cluster-keystore"
```

The Secret must contain the following keys (configurable via `storePasswordKey` / `keyPasswordKey` / `keystoreFile`):

| Secret key | Content |
|---|---|
| `reshapr-cluster.jceks` | The JCEKS keystore binary file |
| `store-password` | Keystore store password (plain text) |
| `key-password` | Keystore key password (plain text) |

If your Secret uses different key names:

```yaml
clustering:
  encryption:
    existingSecret: "my-cluster-keystore"
    keystoreFile: "my-keystore.jceks"
    storePasswordKey: "my-store-pwd"
    keyPasswordKey: "my-key-pwd"
    alias: "my-alias"
```

### Key rotation

To rotate the encryption key:
1. Generate a new keystore (Step 1 above)
2. Update the Secret in-place: `kubectl create secret generic ... --dry-run=client -o yaml | kubectl apply -f -`
3. Perform a rolling restart: `kubectl rollout restart deployment -n <namespace> <release>-reshapr-proxy`

All pods must restart simultaneously with the new key — a gradual rollout would split the cluster. Consider setting `maxUnavailable: 100%` in the Deployment strategy for this operation.

## Gateway ID Generation

The gateway ID is automatically generated using the pod name to ensure uniqueness:

- **Without prefix**: `RESHAPR_GATEWAY_ID = <pod-name>`
- **With prefix**: `RESHAPR_GATEWAY_ID = <prefix>-<pod-name>`

Example:
```yaml
gateway:
  idPrefix: "prod-gateway"
```

This will generate IDs like: `prod-gateway-reshapr-proxy-5d7c8f9b-abcde`

## Examples

### Single Gateway Instance

```yaml
replicaCount: 1

gateway:
  fqdns: "mcp.example.com"
  labels: "env=dev;region=us-east-1"
  controlPlane:
    host: "reshapr-ctrl.reshapr-system.svc.cluster.local"
    port: 5555
    existingSecret: "reshapr-token"
```

### High Availability with Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

gateway:
  idPrefix: "prod-gateway"
  fqdns: "mcp.example.com,api.mcp.example.com"
  labels: "env=production;cluster=prod-01"
  
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - reshapr-proxy
          topologyKey: kubernetes.io/hostname
```

### With Ingress and TLS

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: mcp.reshapr.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: reshapr-proxy-tls
      hosts:
        - mcp.reshapr.example.com

gateway:
  fqdns: "mcp.reshapr.example.com"
```

### With Prometheus Monitoring

```yaml
serviceMonitor:
  enabled: true
  additionalLabels:
    prometheus: kube-prometheus
  interval: 15s
  scrapeTimeout: 10s
```

### Multi-Region Deployment

```yaml
# Region 1
gateway:
  idPrefix: "eu-west-1"
  fqdns: "mcp-eu.reshapr.example.com"
  labels: "env=production;region=eu-west-1"

nodeSelector:
  topology.kubernetes.io/region: eu-west-1

---
# Region 2
gateway:
  idPrefix: "us-east-1"
  fqdns: "mcp-us.reshapr.example.com"
  labels: "env=production;region=us-east-1"

nodeSelector:
  topology.kubernetes.io/region: us-east-1
```

## Upgrading

```bash
helm upgrade reshapr-proxy ./charts/gateway \
  --namespace reshapr-proxies \
  --reuse-values
```

## Uninstalling

```bash
helm uninstall reshapr-proxy --namespace reshapr-proxies
```

## Security Considerations

1. **Always use existing secrets** for the control plane token in production
2. **Set a strong token** (at least 32 characters, random)
3. **Enable TLS** for ingress in production
4. **Use Pod Security Standards** in your namespace
5. **Review and adjust resource limits** based on your workload
6. **Enable NetworkPolicies** to restrict traffic

## Troubleshooting

### Check pod status

```bash
kubectl get pods -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy
```

### View logs

```bash
kubectl logs -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy -f
```

### Check gateway registration with control plane

```bash
# Get gateway pod
GATEWAY_POD=$(kubectl get pod -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy -o jsonpath='{.items[0].metadata.name}')

# Check environment variables
kubectl exec -n reshapr-proxies $GATEWAY_POD -- env | grep RESHAPR

# Check connectivity to control plane
kubectl exec -n reshapr-proxies $GATEWAY_POD -- curl -v http://reshapr-control-plane-ctrl:5555/q/health
```

### Verify unique gateway IDs

```bash
kubectl get pods -n reshapr-proxies -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
```

Each pod will generate a unique gateway ID based on its name.

## Architecture

```
┌─────────────────────────────────────────┐
│          Ingress (Optional)             │
│     mcp.reshapr.example.com             │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│       Service (ClusterIP/LB)            │
│       Port: 7777                        │
└──────────────┬──────────────────────────┘
               │
      ┌────────┴────────┬─────────┐
      ▼                 ▼         ▼
┌─────────┐       ┌─────────┐   ...
│  Proxy  │       │  Proxy  │
│  Pod 1  │       │  Pod 2  │
│ ID: gw-1│       │ ID: gw-2│
└────┬────┘       └────┬────┘
     │                 │
     └────────┬────────┘
              ▼
    ┌──────────────────┐
    │  Control Plane   │
    │  reshapr-ctrl    │
    │  Port: 5555      │
    └──────────────────┘
```

## Contributing

Please see the main Reshapr repository for contribution guidelines.

## License

See the main Reshapr repository for license information.
