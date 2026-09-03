# Reshapr Controllers - Useful Commands

## Installation

### Default Installation (operator + admission webhook)

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace \
  --wait
```

### Operator only

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace \
  --set admissionController.enabled=false \
  --wait
```

### Admission webhook only

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace \
  --set operator.enabled=false \
  --wait
```

### With a specific certificate provider

```bash
# OpenShift service-ca-operator
helm install reshapr-controllers ./controllers -n reshapr-system --create-namespace \
  --set admissionController.certificate.provider=openshift

# Bring-Your-Own certificate (existing Secret + caBundle)
helm install reshapr-controllers ./controllers -n reshapr-system --create-namespace \
  --set admissionController.certificate.provider=existing \
  --set admissionController.certificate.existing.secretName=my-tls-secret \
  --set admissionController.certificate.caBundle=$(base64 -w0 ca.crt)
```

### Dry run

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --dry-run --debug
```

## Verification

```bash
helm list -n reshapr-system
helm status reshapr-controllers -n reshapr-system

# Pods
kubectl get pods -n reshapr-system -l app.kubernetes.io/instance=reshapr-controllers

# CRDs
kubectl get crd | grep reshapr.io
```

## Logs

```bash
# Operator
kubectl logs -n reshapr-system -l app.kubernetes.io/component=operator -f

# Admission webhook
kubectl logs -n reshapr-system -l app.kubernetes.io/component=admission -f
```

## Webhook & certificates

```bash
# Webhook registration and injected caBundle
kubectl get mutatingwebhookconfigurations reshapr-controllers-mutating-webhook -o yaml

# cert-manager certificate status
kubectl get certificate,issuer -n reshapr-system
kubectl describe certificate reshapr-controllers-admission-serving-cert -n reshapr-system

# Serving certificate Secret
kubectl get secret reshapr-controllers-admission-tls -n reshapr-system
```

## Operator registration on the control plane

```bash
export RESHAPR_ADMIN_API_KEY='<admin-api-key>'

reshapr admin --server https://reshapr.acme.loc \
  service-account create reshapr-system-operator \
  --k8s-subject reshapr-system:reshapr-controllers-operator \
  --allowed-organizations '["*"]' \
  --validity-days 90
```

## CRD management

```bash
# Refresh CRDs from upstream
./sync-crds.sh
REF=0.0.1 ./sync-crds.sh

# Apply CRDs manually (when installing with --skip-crds)
kubectl apply -f crds/
```

## Testing

```bash
# Lint + render (default, operator-only, admission-only, each cert provider, dev/prod values)
./test-chart.sh

# Manual checks
helm lint ./controllers
helm template reshapr-controllers ./controllers
helm template reshapr-controllers ./controllers --set operator.enabled=false
```

## Upgrade

```bash
helm upgrade reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --reuse-values
```

## Cleanup

```bash
helm uninstall reshapr-controllers -n reshapr-system

# CRDs are NOT removed by Helm. Delete them manually only if you want to drop all CRs:
kubectl delete -f controllers/crds/
```
