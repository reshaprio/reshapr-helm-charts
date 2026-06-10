# Reshapr Web UI Helm Chart

This Helm chart deploys the Reshapr Web UI dashboard on a Kubernetes cluster.

## Components

This chart installs the **reshapr-web-ui** component, a web dashboard for managing reShapr.

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- A running Reshapr Control Plane (the web-ui connects to it via `controlPlane.url`)

## Installing the Chart

### Basic Installation

```bash
helm install reshapr-web-ui ./web-ui \
  --namespace reshapr-system \
  --create-namespace \
  --set apiKey.value=<your-api-key> \
  --set publicUrl=http://reshapr-ui.acme.loc \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=reshapr-ui.acme.loc \
  --wait
```

### Development Installation

```bash
helm install reshapr-web-ui ./web-ui \
  --namespace reshapr-system \
  --create-namespace \
  -f values-dev.yaml \
  --wait
```

### Production Installation

```bash
# Create the API key secret first
kubectl create secret generic reshapr-web-ui-api-key \
  --from-literal=api-key='your-admin-api-key' \
  --namespace reshapr-system

# Install the chart
helm install reshapr-web-ui ./web-ui \
  --namespace reshapr-system \
  --create-namespace \
  -f values-production.yaml \
  --wait
```

### With Ingress

```bash
helm install reshapr-web-ui ./web-ui \
  --namespace reshapr-system \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set 'ingress.hosts[0].host=ui.reshapr.example.com' \
  --set apiKey.value='your-admin-api-key' \
  --wait
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `registry.reshapr.io/reshapr/reshapr-web-ui` |
| `image.tag` | Image tag | `nightly` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `3333` |
| `controlPlane.url` | Control plane internal URL | `http://reshapr-control-plane-ctrl:5555` |
| `controlPlane.publicUrl` | Control plane public URL | `""` |
| `apiKey.value` | Admin API key value | `""` |
| `apiKey.existingSecret` | Existing secret for API key | `""` |
| `apiKey.key` | Key in secret | `api-key` |
| `publicUrl` | Web UI public URL | `""` |
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `podDisruptionBudget.enabled` | Enable PDB | `false` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `256Mi` |
| `resources.requests.cpu` | CPU request | `50m` |
| `resources.requests.memory` | Memory request | `128Mi` |

## Security Considerations

1. **Use existing secrets** in production for the API key instead of passing it as a value
2. **Enable TLS** for ingress in production
3. **Review and adjust resource limits** based on your workload
