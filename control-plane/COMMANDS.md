# Reshapr Control Plane - Useful Commands

## Installation

### Development Installation (with embedded PostgreSQL)

```bash
helm install reshapr-control-plane ./control-plane \
  --namespace reshapr-system \
  --set postgresql.enabled=true \
  --set postgresql.auth.password=admin \
  --set apiKey.value=dev-api-key-change-me-in-production \
  --set encryptionKey.value=dev-encryption-key-change-me-in-production
```

```bash
# Add bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Build dependencies
helm dependency build .

# Install the chart
helm install reshapr-control-plane . \
  --namespace reshapr-system \
  --create-namespace \
  -f values-dev.yaml \
  --wait
```

### Production Installation (with external PostgreSQL)
```bash
# Create secrets first
kubectl create secret generic reshapr-db-credentials \
  --from-literal=password='your-secure-password' \
  --namespace reshapr-system

kubectl create secret generic reshapr-authz-admin-secret \
  --from-literal=username='admin' \
  --from-literal=password='your-admin-password' \
  --namespace reshapr-system

kubectl create secret generic reshapr-api-key-secret \
  --from-literal=api-key='your-very-long-random-api-key' \
  --namespace reshapr-system

# Install the chart
helm install reshapr-control-plane . \
  --namespace reshapr-system \
  --create-namespace \
  -f values-production.yaml \
  --set externalDatabase.host=postgresql.example.com \
  --set ingress.ctrl.host=api.reshapr.example.com \
  --wait
```

## Verification

### Check installation status
```bash
helm list -n reshapr-system
helm status reshapr-control-plane -n reshapr-system
```

### Check pods
```bash
kubectl get pods -n reshapr-system
kubectl get pods -n reshapr-system -l app.kubernetes.io/instance=reshapr-control-plane
```

### Check services
```bash
kubectl get svc -n reshapr-system
```

### Check secrets
```bash
kubectl get secrets -n reshapr-system
```

### View logs
```bash
# Control Plane logs
kubectl logs -n reshapr-system -l app.kubernetes.io/component=ctrl -f

# Authorization logs
kubectl logs -n reshapr-system -l app.kubernetes.io/component=authz -f

# PostgreSQL logs (if embedded)
kubectl logs -n reshapr-system -l app.kubernetes.io/name=postgresql -f
```

## Access Services

### Port Forwarding (when ingress is not enabled)
```bash
# Control Plane API
kubectl port-forward -n reshapr-system svc/reshapr-control-plane-ctrl 5555:5555

# Authorization (Keycloak)
kubectl port-forward -n reshapr-system svc/reshapr-control-plane-authz 8080:8080

# PostgreSQL (if embedded)
kubectl port-forward -n reshapr-system svc/reshapr-control-plane-postgresql 5432:5432
```

### Access via Ingress
```bash
# Control Plane API
curl https://api.reshapr.example.com/q/health

# Keycloak Admin Console
open https://idp.reshapr.example.com/admin
```

## Debugging

### Describe resources
```bash
# Describe ctrl deployment
kubectl describe deployment -n reshapr-system reshapr-control-plane-ctrl

# Describe authz deployment
kubectl describe deployment -n reshapr-system reshapr-control-plane-authz

# Describe pods
kubectl describe pod -n reshapr-system -l app.kubernetes.io/component=ctrl
kubectl describe pod -n reshapr-system -l app.kubernetes.io/component=authz
```

### Execute commands in pods
```bash
# Get a shell in ctrl pod
kubectl exec -it -n reshapr-system deployment/reshapr-control-plane-ctrl -- sh

# Get a shell in authz pod
kubectl exec -it -n reshapr-system deployment/reshapr-control-plane-authz -- sh

# Test database connection from ctrl pod
kubectl exec -n reshapr-system deployment/reshapr-control-plane-ctrl -- \
  sh -c 'echo "SELECT 1" | psql $QUARKUS_DATASOURCE_JDBC_URL -U $QUARKUS_DATASOURCE_USERNAME'
```

### Check events
```bash
kubectl get events -n reshapr-system --sort-by='.lastTimestamp'
```

## Configuration Updates

### Update values
```bash
# Upgrade with new values
helm upgrade reshapr-control-plane . \
  --namespace reshapr-system \
  -f values-dev.yaml \
  --set ctrl.replicaCount=3 \
  --wait
```

### Rollback
```bash
# List revisions
helm history reshapr-control-plane -n reshapr-system

# Rollback to previous version
helm rollback reshapr-control-plane -n reshapr-system

# Rollback to specific revision
helm rollback reshapr-control-plane 2 -n reshapr-system
```

## Testing

### Dry run installation
```bash
helm install reshapr-control-plane . \
  --namespace reshapr-system \
  -f values-dev.yaml \
  --dry-run \
  --debug
```

### Template rendering
```bash
# Render all templates
helm template reshapr-control-plane . -f values-dev.yaml

# Render specific template
helm template reshapr-control-plane . -f values-dev.yaml -s templates/ctrl-deployment.yaml

# Save rendered templates to file
helm template reshapr-control-plane . -f values-dev.yaml > rendered-manifests.yaml
```

### Validate templates
```bash
# Lint the chart
helm lint .

# Lint with specific values
helm lint . -f values-production.yaml
```

## Cleanup

### Uninstall
```bash
# Uninstall release (keeps PVCs)
helm uninstall reshapr-control-plane -n reshapr-system

# Delete namespace (deletes everything including PVCs)
kubectl delete namespace reshapr-system
```

### Delete specific resources
```bash
# Delete secrets only
kubectl delete secret -n reshapr-system reshapr-db-credentials
kubectl delete secret -n reshapr-system reshapr-authz-admin-secret
kubectl delete secret -n reshapr-system reshapr-api-key-secret

# Delete PVCs
kubectl delete pvc -n reshapr-system -l app.kubernetes.io/instance=reshapr-control-plane
```

## Backup and Restore

### Backup PostgreSQL data (if using embedded)
```bash
# Create a backup
kubectl exec -n reshapr-system reshapr-control-plane-postgresql-0 -- \
  pg_dump -U reshapr reshapr > backup-$(date +%Y%m%d-%H%M%S).sql
```

### Export helm values
```bash
# Get current values
helm get values reshapr-control-plane -n reshapr-system > current-values.yaml

# Get all values (including defaults)
helm get values reshapr-control-plane -n reshapr-system --all > all-values.yaml
```

## Monitoring

### Watch pod status
```bash
watch kubectl get pods -n reshapr-system -l app.kubernetes.io/instance=reshapr-control-plane
```

### Resource usage
```bash
# Get resource usage
kubectl top pods -n reshapr-system

# Get resource requests and limits
kubectl describe nodes | grep -A 5 "reshapr-system"
```

## Secrets Management

### Create secrets from files
```bash
# Database credentials
kubectl create secret generic reshapr-db-credentials \
  --from-file=password=./db-password.txt \
  --namespace reshapr-system

# API key
kubectl create secret generic reshapr-api-key-secret \
  --from-file=api-key=./api-key.txt \
  --namespace reshapr-system
```

### Update secrets
```bash
# Update database password
kubectl create secret generic reshapr-db-credentials \
  --from-literal=password='new-password' \
  --namespace reshapr-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new secrets
kubectl rollout restart deployment/reshapr-control-plane-ctrl -n reshapr-system
kubectl rollout restart deployment/reshapr-control-plane-authz -n reshapr-system
```

## Scaling

### Scale deployments
```bash
# Scale ctrl
kubectl scale deployment/reshapr-control-plane-ctrl -n reshapr-system --replicas=3

# Using helm
helm upgrade reshapr-control-plane . \
  --namespace reshapr-system \
  --reuse-values \
  --set ctrl.replicaCount=3
```

## Health Checks

### Check liveness and readiness
```bash
# Get ctrl pod
CTRL_POD=$(kubectl get pod -n reshapr-system -l app.kubernetes.io/component=ctrl -o jsonpath='{.items[0].metadata.name}')

# Test liveness
kubectl exec -n reshapr-system $CTRL_POD -- curl -f http://localhost:5555/q/health/live

# Test readiness
kubectl exec -n reshapr-system $CTRL_POD -- curl -f http://localhost:5555/q/health/ready
```
