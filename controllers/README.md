# Reshapr Controllers Helm Chart

This Helm chart deploys the Reshapr Controllers components (Operator and Admission Webhook) on a Kubernetes cluster. 

## Components

This chart allows you to install the following components independently or together:

- **Operator**: Reconciles Reshapr Custom Resources.
- **Admission Controller**: Validating webhook to ensure the integrity of Reshapr Custom Resources.

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- [cert-manager](https://cert-manager.io/) (Required if deploying the Admission Controller, to automatically generate webhook certificates)

## Installing the Chart

By default, both the Operator and the Admission Controller are enabled.

### Default Installation (Both Components)

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace
```

### Install Only the Operator

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace \
  --set admissionController.enabled=false
```

### Install Only the Admission Controller

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --create-namespace \
  --set operator.enabled=false
```

## OpenShift Compatibility

This chart is fully compatible with OpenShift's `restricted-v2` Security Context Constraints (SCC). The `podSecurityContext` and `securityContext` are left empty by default to allow OpenShift to dynamically inject the correct UIDs.

## Custom Resource Definitions (CRDs)

By default, Helm will automatically install the CRDs located in the `crds/` folder before installing any other resources. If you are upgrading an existing cluster and wish to skip CRD installation, you can use the standard Helm flag:

```bash
helm install reshapr-controllers ./controllers \
  --namespace reshapr-system \
  --skip-crds
```

To sync the latest CRDs from the upstream `reshapr-controllers` repository, you can run the provided sync script:

```bash
./controllers/sync-crds.sh
```

## Parameters

| Parameter                          | Description                  | Default                         |
|------------------------------------|------------------------------|---------------------------------|
| `operator.enabled`                 | Enable operator component    | `true`                          |
| `operator.replicaCount`            | Number of operator replicas  | `1`                             |
| `operator.image.repository`        | Image repository             | `registry.reshapr.io/reshapr/reshapr-operator` |
| `operator.image.tag`               | Image tag                    | `nightly`                       |
| `operator.image.pullPolicy`        | Image pull policy            | `IfNotPresent`                  |
| `admissionController.enabled`      | Enable admission webhook     | `true`                          |
| `admissionController.replicaCount` | Number of webhook replicas   | `1`                             |
| `admissionController.image.repository` | Image repository         | `registry.reshapr.io/reshapr/reshapr-admission` |
| `admissionController.image.tag`    | Image tag                    | `nightly`                       |
| `admissionController.image.pullPolicy` | Image pull policy        | `IfNotPresent`                  |
| `serviceAccount.create`            | Create service account       | `true`                          |
| `serviceAccount.name`              | Service account name         | `""`                            |
| `podSecurityContext`               | Pod Security Context         | `{}`                            |
| `securityContext`                  | Security Context             | `{}`                            |
