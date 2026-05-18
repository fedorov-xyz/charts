{{- define "redis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "redis.fullname" -}}
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

{{- define "redis.labels" -}}
helm.sh/chart: {{ include "redis.chart" . }}
{{ include "redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "redis.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "redis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: redis
{{- end }}

{{- define "redis.authSecretName" -}}
{{- required "auth.existingSecret is required" .Values.auth.existingSecret }}
{{- end }}

{{- define "redis.authSecretKey" -}}
{{- .Values.auth.existingSecretPasswordKey | default "password" }}
{{- end }}

{{- define "redis.configChecksum" -}}
{{- pick (include (print $.Template.BasePath "/configmap.yaml") . | fromYaml) "data" | toYaml | sha256sum }}
{{- end }}

{{- define "redis.authChecksum" -}}
{{- printf "%s/%s" (required "auth.existingSecret is required" .Values.auth.existingSecret) (include "redis.authSecretKey" .) | sha256sum }}
{{- end }}
