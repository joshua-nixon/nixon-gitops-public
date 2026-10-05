{{/*
Expand the name of the chart.
*/}}
{{- define "nixon-cnpg-cluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nixon-cnpg-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nixon-cnpg-cluster.labels" -}}
helm.sh/chart: {{ include "nixon-cnpg-cluster.chart" . }}
{{ include "nixon-cnpg-cluster.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nixon-cnpg-cluster.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nixon-cnpg-cluster.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "nixon-cnpg-cluster.externalObjectStore" -}}
{{- printf "%s-external-store" (include "nixon-cnpg-cluster.name" .) | trim -}}
{{- end }}

{{- define "nixon-cnpg-cluster.userResourceName" -}}
{{- printf "%s-%s" (include "nixon-cnpg-cluster.name" .root) (replace "_" "-" .name) | trim -}}
{{- end }}