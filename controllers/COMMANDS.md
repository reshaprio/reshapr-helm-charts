# Reshapr Controllers - Useful Commands

## Installation

### Default Installation

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace \
  --wait
```

### Dry run installation
```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --dry-run \
  --debug
```

## Verification

### Check installation status
```bash
helm list -n reshapr-system
helm status reshapr-controllers -n reshapr-system
```

### Check pods
```bash
kubectl get pods -n reshapr-system -l app.kubernetes.io/name=reshapr-controllers
```

### View logs
```bash
# Operator logs
kubectl logs -n reshapr-system -l app.kubernetes.io/component=operator -f

# Admission Controller logs
kubectl logs -n reshapr-system -l app.kubernetes.io/component=admission -f
```

## Debugging

### Describe pods
```bash
kubectl describe pod -n reshapr-system -l app.kubernetes.io/component=operator
kubectl describe pod -n reshapr-system -l app.kubernetes.io/component=admission
```

### Check Webhook Configuration
```bash
kubectl get validatingwebhookconfigurations -l app.kubernetes.io/name=reshapr-controllers
```

## Testing

### Validate templates
```bash
helm lint ./controllers
```

### Template rendering
```bash
helm template reshapr-controllers ./controllers
```

## Cleanup

### Uninstall
```bash
helm uninstall reshapr-controllers -n reshapr-system
```
