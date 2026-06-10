{{/*
Expand the name of the chart.
*/}}
{{- define "reshapr-web-ui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "reshapr-web-ui.fullname" -}}
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
{{- define "reshapr-web-ui.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "reshapr-web-ui.labels" -}}
helm.sh/chart: {{ include "reshapr-web-ui.chart" . }}
{{ include "reshapr-web-ui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "reshapr-web-ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "reshapr-web-ui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "reshapr-web-ui.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "reshapr-web-ui.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the API key secret name
Supports templated values (e.g. "{{ .Release.Name }}-reshapr-control-plane-api-key")
so the web-ui can reuse the control-plane's secret when embedded as a subchart.
*/}}
{{- define "reshapr-web-ui.apiKeySecretName" -}}
{{- if .Values.apiKey.existingSecret }}
{{- tpl .Values.apiKey.existingSecret . }}
{{- else }}
{{- printf "%s-api-key" (include "reshapr-web-ui.fullname" .) }}
{{- end }}
{{- end }}
