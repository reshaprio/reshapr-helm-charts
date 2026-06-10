# Reshapr Web UI - Useful Commands

## Installation

### Development Installation

Assuming you have CertManager installed with a `ClusterIssuer` named `reshapr-admission-controller-issue`:

```bash
helm install reshapr-web-ui ./web-ui \
  --namespace reshapr-system \
  --create-namespace \
  --set apiKey.value=dev-api-key-change-me-in-production \
  --set publicUrl=https://reshapr-ui.acme.loc \
  --set ingress.enabled=true \
  --set ingress.annotations."cert\-manager\.io\/cluster\-issuer"=reshapr-admission-controller-issuer \
  --set 'ingress.hosts[0].host=reshapr-ui.acme.loc' \
  --set 'ingress.tls[0].hosts[0]=reshapr-ui.acme.loc' \
  --set 'ingress.tls[0].secretName=reshapr-web-ui-tls'
```

### Production Installation

```bash
# Create API key secret
kubectl create secret generic reshapr-web-ui-api-key \
  --from-literal=api-key='your-admin-api-key' \
  --namespace reshapr-system

# Install
helm install reshapr-web-ui . \
  --namespace reshapr-system \
  --create-namespace \
  -f values-production.yaml \
  --wait
```

## Verification

### Check installation status
```bash
helm list -n reshapr-system
helm status reshapr-web-ui -n reshapr-system
```

### Check pods
```bash
kubectl get pods -n reshapr-system -l app.kubernetes.io/instance=reshapr-web-ui
```

### Check services
```bash
kubectl get svc -n reshapr-system
```

### View logs
```bash
kubectl logs -n reshapr-system -l app.kubernetes.io/instance=reshapr-web-ui -f
```

## Access Services

### Port Forwarding (when ingress is not enabled)
```bash
kubectl port-forward -n reshapr-system svc/reshapr-web-ui 3333:3333
```

### Access via Ingress
```bash
open https://ui.reshapr.example.com
```

## Debugging

### Describe resources
```bash
kubectl describe deployment -n reshapr-system reshapr-web-ui
kubectl describe pod -n reshapr-system -l app.kubernetes.io/instance=reshapr-web-ui
```

### Execute commands in pods
```bash
kubectl exec -it -n reshapr-system deployment/reshapr-web-ui -- sh
```

### Check events
```bash
kubectl get events -n reshapr-system --sort-by='.lastTimestamp'
```

## Configuration Updates

### Update values
```bash
helm upgrade reshapr-web-ui . \
  --namespace reshapr-system \
  -f values-dev.yaml \
  --set replicaCount=2 \
  --wait
```

### Rollback
```bash
helm history reshapr-web-ui -n reshapr-system
helm rollback reshapr-web-ui -n reshapr-system
```

## Testing

### Dry run installation
```bash
helm install reshapr-web-ui . \
  --namespace reshapr-system \
  -f values-dev.yaml \
  --dry-run \
  --debug
```

### Template rendering
```bash
helm template reshapr-web-ui . -f values-dev.yaml
helm template reshapr-web-ui . -f values-dev.yaml -s templates/deployment.yaml
```
