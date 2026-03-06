{{/*
Expand the name of the chart.
*/}}
{{- define "reshapr-ctrl-plane.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "reshapr-ctrl-plane.fullname" -}}
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
{{- define "reshapr-ctrl-plane.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "reshapr-ctrl-plane.labels" -}}
helm.sh/chart: {{ include "reshapr-ctrl-plane.chart" . }}
{{ include "reshapr-ctrl-plane.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "reshapr-ctrl-plane.selectorLabels" -}}
app.kubernetes.io/name: {{ include "reshapr-ctrl-plane.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
=============================================================================
reshapr-ctrl helpers
=============================================================================
*/}}

{{/*
reshapr-ctrl fullname
*/}}
{{- define "reshapr-ctrl.fullname" -}}
{{- printf "%s-ctrl" (include "reshapr-ctrl-plane.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
reshapr-ctrl labels
*/}}
{{- define "reshapr-ctrl.labels" -}}
{{ include "reshapr-ctrl-plane.labels" . }}
app.kubernetes.io/component: ctrl
{{- end }}

{{/*
reshapr-ctrl selector labels
*/}}
{{- define "reshapr-ctrl.selectorLabels" -}}
{{ include "reshapr-ctrl-plane.selectorLabels" . }}
app.kubernetes.io/component: ctrl
{{- end }}

{{/*
Create the name of the service account to use for ctrl
*/}}
{{- define "reshapr-ctrl.serviceAccountName" -}}
{{- if .Values.ctrl.serviceAccount.create }}
{{- default (include "reshapr-ctrl.fullname" .) .Values.ctrl.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.ctrl.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
=============================================================================
Database helpers
=============================================================================
*/}}

{{/*
Get the database host
*/}}
{{- define "reshapr-ctrl-plane.databaseHost" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" (include "reshapr-ctrl-plane.fullname" .) }}
{{- else }}
{{- .Values.externalDatabase.host }}
{{- end }}
{{- end }}

{{/*
Get the database port
*/}}
{{- define "reshapr-ctrl-plane.databasePort" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "5432" }}
{{- else }}
{{- .Values.externalDatabase.port | toString }}
{{- end }}
{{- end }}

{{/*
Get the database name
*/}}
{{- define "reshapr-ctrl-plane.databaseName" -}}
{{- if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.database }}
{{- else }}
{{- .Values.externalDatabase.database }}
{{- end }}
{{- end }}

{{/*
Get the database username
*/}}
{{- define "reshapr-ctrl-plane.databaseUsername" -}}
{{- if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.username }}
{{- else }}
{{- .Values.externalDatabase.username }}
{{- end }}
{{- end }}

{{/*
Get the database secret name
*/}}
{{- define "reshapr-ctrl-plane.databaseSecretName" -}}
{{- if .Values.postgresql.enabled }}
{{- if .Values.postgresql.auth.existingSecret }}
{{- .Values.postgresql.auth.existingSecret }}
{{- else }}
{{- printf "%s-postgresql" (include "reshapr-ctrl-plane.fullname" .) }}
{{- end }}
{{- else }}
{{- if .Values.externalDatabase.existingSecret }}
{{- .Values.externalDatabase.existingSecret }}
{{- else }}
{{- printf "%s-external-db" (include "reshapr-ctrl-plane.fullname" .) }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Get the database password key in secret
*/}}
{{- define "reshapr-ctrl-plane.databaseSecretKey" -}}
{{- if .Values.postgresql.enabled }}
{{- if .Values.postgresql.auth.existingSecret }}
{{- .Values.postgresql.auth.secretKeys.userPasswordKey }}
{{- else }}
{{- printf "password" }}
{{- end }}
{{- else }}
{{- if .Values.externalDatabase.existingSecret }}
{{- .Values.externalDatabase.passwordKey }}
{{- else }}
{{- printf "password" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
=============================================================================
Communication helpers
=============================================================================
*/}}

{{/*
Get the API key secret name
*/}}
{{- define "reshapr-ctrl-plane.apiKeySecretName" -}}
{{- if .Values.apiKey.existingSecret }}
{{- .Values.apiKey.existingSecret }}
{{- else }}
{{- printf "%s-api-key" (include "reshapr-ctrl-plane.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get the Encryption key secret name
*/}}
{{- define "reshapr-ctrl-plane.encryptionKeySecretName" -}}
{{- if .Values.encryptionKey.existingSecret }}
{{- .Values.encryptionKey.existingSecret }}
{{- else }}
{{- printf "%s-encryption-key" (include "reshapr-ctrl-plane.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get the JWT keys secret name
*/}}
{{- define "reshapr-ctrl-plane.jwtKeysSecretName" -}}
{{- if .Values.jwtKeys.existingSecret }}
{{- .Values.jwtKeys.existingSecret }}
{{- else }}
{{- printf "%s-jwt-keys" (include "reshapr-ctrl-plane.fullname" .) }}
{{- end }}
{{- end }}

