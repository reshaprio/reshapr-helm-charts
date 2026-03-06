# Reshpar Proxy - Useful Commands

## Installation

### Development Installation

```bash
helm install reshapr-proxy ./proxy \
  --namespace reshapr-proxies \
  --set gateway.idPrefix=acme \
  --set gateway.labels='env=dev;team=reshapr' \
  --set gateway.fqdns=mcp.acme.loc \
  --set ingress.enabled=true \
  --set 'ingress.hosts[0].host=mcp.acme.loc' \
  --set gateway.controlPlane.host=reshapr-control-plane-ctrl.reshapr-system \
  --set gateway.controlPlane.port=5555 \
  --set gateway.controlPlane.token=reshapr-my-super-secret-token
```

### Manual Installation
```bash
helm install reshapr-proxy . \
  --namespace reshapr-proxies \
  --create-namespace \
  -f values-dev.yaml \
  --wait
```

### Production Installation
```bash
# Create token secret
kubectl create secret generic reshapr-proxy-token \
  --from-literal=token='your-secure-control-plane-token' \
  --namespace reshapr-proxies

# Install
helm install reshapr-proxy . \
  --namespace reshapr-proxies \
  --create-namespace \
  -f values-production.yaml \
  --set gateway.fqdns='mcp.reshapr.example.com' \
  --set ingress.hosts[0].host='mcp.reshapr.example.com' \
  --wait
```

## Verification

### Check installation status
```bash
helm list -n reshapr-proxies
helm status reshapr-proxy -n reshapr-proxies
```

### Check pods
```bash
kubectl get pods -n reshapr-proxies
kubectl get pods -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy -w
```

### Check gateway IDs
```bash
# Get all gateway pods and their IDs
kubectl get pods -n reshapr-proxies -o wide

# Check RESHAPR_GATEWAY_ID environment variable in pods
kubectl get pods -n reshapr-proxies -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
```

### View logs
```bash
# All gateways
kubectl logs -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy -f

# Specific pod
kubectl logs -n reshapr-proxies <pod-name> -f

# With timestamps
kubectl logs -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy -f --timestamps
```

### Check environment variables
```bash
# Get a pod
GATEWAY_POD=$(kubectl get pod -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy -o jsonpath='{.items[0].metadata.name}')

# View all RESHAPR env vars
kubectl exec -n reshapr-proxies $GATEWAY_POD -- env | grep RESHAPR

# View specific vars
kubectl exec -n reshapr-proxies $GATEWAY_POD -- sh -c 'echo "Gateway ID: $RESHAPR_GATEWAY_ID"'
kubectl exec -n reshapr-proxies $GATEWAY_POD -- sh -c 'echo "FQDNs: $RESHAPR_GATEWAY_FQDNS"'
kubectl exec -n reshapr-proxies $GATEWAY_POD -- sh -c 'echo "Labels: $RESHAPR_GATEWAY_LABELS"'
```

## Access Services

### Port Forwarding
```bash
# Single port forward
kubectl port-forward -n reshapr-proxies svc/reshapr-proxy 7777:7777

# Access health endpoints
curl http://localhost:7777/q/health/live
curl http://localhost:7777/q/health/ready
curl http://localhost:7777/q/metrics
```

### Via Ingress
```bash
# Check ingress
kubectl get ingress -n reshapr-proxies

# Access via FQDN
curl https://mcp.reshapr.example.com/q/health
```

## Debugging

### Describe resources
```bash
# Deployment
kubectl describe deployment -n reshapr-proxies reshapr-proxy

# Pods
kubectl describe pod -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy

# Service
kubectl describe svc -n reshapr-proxies reshapr-proxy

# HPA (if enabled)
kubectl describe hpa -n reshapr-proxies reshapr-proxy
```

### Execute commands in pods
```bash
# Get a shell
kubectl exec -it -n reshapr-proxies deployment/reshapr-proxy -- sh

# Test control plane connectivity
kubectl exec -n reshapr-proxies deployment/reshapr-proxy -- \
  curl -v http://reshapr-control-plane-ctrl.reshapr-system:5555/q/health
```

### Check secrets
```bash
# List secrets
kubectl get secrets -n reshapr-proxies

# View secret (base64 encoded)
kubectl get secret -n reshapr-proxies reshapr-proxy-token -o yaml

# Decode secret
kubectl get secret -n reshapr-proxies reshapr-proxy-token -o jsonpath='{.data.token}' | base64 -d
```

### Check events
```bash
kubectl get events -n reshapr-proxies --sort-by='.lastTimestamp'
kubectl get events -n reshapr-proxies --field-selector involvedObject.name=reshapr-proxy
```

## Scaling

### Manual scaling (without HPA)
```bash
# Scale up
kubectl scale deployment/reshapr-proxy -n reshapr-proxies --replicas=5

# Using helm
helm upgrade reshapr-proxy . \
  --namespace reshapr-proxies \
  --reuse-values \
  --set replicaCount=5
```

### Autoscaling (with HPA)
```bash
# Check HPA status
kubectl get hpa -n reshapr-proxies reshapr-proxy

# Watch HPA
kubectl get hpa -n reshapr-proxies reshapr-proxy -w

# Describe HPA
kubectl describe hpa -n reshapr-proxies reshapr-proxy

# Enable HPA via helm
helm upgrade reshapr-proxy . \
  --namespace reshapr-proxies \
  --reuse-values \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=10
```

### Check resource usage
```bash
# Pod resource usage
kubectl top pods -n reshapr-proxies

# Node resource usage
kubectl top nodes
```

## Configuration Updates

### Update gateway configuration
```bash
# Update FQDNs
helm upgrade reshapr-proxy . \
  --namespace reshapr-proxies \
  --reuse-values \
  --set gateway.fqdns='mcp.example.com,api.mcp.example.com'

# Update labels
helm upgrade reshapr-proxy . \
  --namespace reshapr-proxies \
  --reuse-values \
  --set gateway.labels='env=production,region=eu-west-1,version=v2'

# Update control plane host
helm upgrade reshapr-proxy . \
  --namespace reshapr-proxies \
  --reuse-values \
  --set gateway.controlPlane.host='new-ctrl-host'
```

### Update token secret
```bash
# Create new token
kubectl create secret generic reshapr-proxy-token \
  --from-literal=token='new-secure-token' \
  --namespace reshapr-proxies \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new token
kubectl rollout restart deployment/reshapr-proxy -n reshapr-proxies
```

### Rolling update
```bash
# Update image tag
helm upgrade reshapr-proxy . \
  --namespace reshapr-proxies \
  --reuse-values \
  --set image.tag='v1.2.3'

# Watch rollout
kubectl rollout status deployment/reshapr-proxy -n reshapr-proxies

# Check rollout history
kubectl rollout history deployment/reshapr-proxy -n reshapr-proxies
```

## Rollback

### Helm rollback
```bash
# List revisions
helm history reshapr-proxy -n reshapr-proxies

# Rollback to previous version
helm rollback reshapr-proxy -n reshapr-proxies

# Rollback to specific revision
helm rollback reshapr-proxy 3 -n reshapr-proxies
```

### Kubernetes rollback
```bash
# Rollback deployment
kubectl rollout undo deployment/reshapr-proxy -n reshapr-proxies

# Rollback to specific revision
kubectl rollout undo deployment/reshapr-proxy -n reshapr-proxies --to-revision=2
```

## Testing

### Template rendering
```bash
# Render all templates
helm template reshapr-proxy . -f values-dev.yaml

# Render specific template
helm template reshapr-proxy . -s templates/deployment.yaml

# Save rendered templates
helm template reshapr-proxy . -f values-production.yaml > manifests.yaml
```

### Dry run installation
```bash
helm install reshapr-proxy . \
  --namespace reshapr-proxies \
  -f values-dev.yaml \
  --dry-run \
  --debug
```

### Validate templates
```bash
# Lint chart
helm lint .

# Lint with specific values
helm lint . -f values-production.yaml
```

### Test connectivity
```bash
# From within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://reshapr-proxy.reshapr-proxies:7777/q/health

# Test control plane connectivity from gateway
GATEWAY_POD=$(kubectl get pod -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n reshapr-proxies $GATEWAY_POD -- \
  curl -v http://reshapr-control-plane-ctrl.reshapr-system:5555/q/health
```

## Monitoring

### Prometheus metrics
```bash
# Access metrics endpoint
kubectl port-forward -n reshapr-proxies svc/reshapr-proxy 7777:7777
curl http://localhost:7777/q/metrics

# Check ServiceMonitor
kubectl get servicemonitor -n reshapr-proxies
kubectl describe servicemonitor -n reshapr-proxies reshapr-proxy
```

### Watch resources
```bash
# Watch pods
watch kubectl get pods -n reshapr-proxies

# Watch HPA
watch kubectl get hpa -n reshapr-proxies

# Watch all resources
kubectl get all -n reshapr-proxies -w
```

## Multi-Gateway Deployment

### Deploy multiple gateway instances
```bash
# EU Gateway
helm install reshapr-proxy-eu . \
  -n reshapr-proxies \
  --set gateway.idPrefix='eu-west-1' \
  --set gateway.fqdns='mcp-eu.example.com' \
  --set gateway.labels='env=prod,region=eu-west-1'

# US Gateway
helm install reshapr-proxy-us . \
  -n reshapr-proxies \
  --set gateway.idPrefix='us-east-1' \
  --set gateway.fqdns='mcp-us.example.com' \
  --set gateway.labels='env=prod,region=us-east-1'

# List all gateways
helm list -n reshapr-proxies
kubectl get pods -n reshapr-proxies
```

## Cleanup

### Uninstall
```bash
# Uninstall release
helm uninstall reshapr-proxy -n reshapr-proxies

# Delete namespace (deletes everything)
kubectl delete namespace reshapr-proxies
```

### Clean specific resources
```bash
# Delete secrets
kubectl delete secret -n reshapr-proxies reshapr-proxy-token

# Delete PVCs (if any)
kubectl delete pvc -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy
```

## Troubleshooting Tips

### Gateway not connecting to control plane
```bash
# Check control plane is accessible
kubectl run -it --rm debug --image=curlimages/curl -n reshapr-proxies --restart=Never -- \
  curl -v http://reshapr-control-plane-ctrl.reshapr-system:5555/q/health

# Check token is correct
kubectl get secret -n reshapr-proxies reshapr-proxy-token -o jsonpath='{.data.token}' | base64 -d

# Check gateway logs for connection errors
kubectl logs -n reshapr-proxies -l app.kubernetes.io/instance=reshapr-proxy | grep -i error
```

### Pods not starting
```bash
# Check pod status
kubectl get pods -n reshapr-proxies -o wide

# Check pod events
kubectl describe pod -n reshapr-proxies <pod-name>

# Check if image exists
kubectl get pods -n reshapr-proxies -o jsonpath='{.items[*].spec.containers[*].image}'
```

### HPA not scaling
```bash
# Check metrics server
kubectl get apiservice v1beta1.metrics.k8s.io

# Check HPA conditions
kubectl describe hpa -n reshapr-proxies reshapr-proxy

# Check current metrics
kubectl get hpa -n reshapr-proxies reshapr-proxy -o yaml
```
