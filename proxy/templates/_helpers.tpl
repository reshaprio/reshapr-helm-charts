{{/*
Expand the name of the chart.
*/}}
{{- define "reshapr-proxy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "reshapr-proxy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "reshapr-proxy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "reshapr-proxy.labels" -}}
helm.sh/chart: {{ include "reshapr-proxy.chart" . }}
{{ include "reshapr-proxy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "reshapr-proxy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "reshapr-proxy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "reshapr-proxy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "reshapr-proxy.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the control plane token secret name
*/}}
{{- define "reshapr-proxy.tokenSecretName" -}}
{{- if .Values.gateway.controlPlane.existingSecret }}
{{- .Values.gateway.controlPlane.existingSecret }}
{{- else }}
{{- printf "%s-token" (include "reshapr-proxy.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Generate the gateway ID from pod name and optional prefix
*/}}
{{- define "reshapr-proxy.gatewayId" -}}
{{- if .Values.gateway.idPrefix }}
{{- printf "%s-$(POD_NAME)" .Values.gateway.idPrefix }}
{{- else }}
{{- printf "$(POD_NAME)" }}
{{- end }}
{{- end }}
