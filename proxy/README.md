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
