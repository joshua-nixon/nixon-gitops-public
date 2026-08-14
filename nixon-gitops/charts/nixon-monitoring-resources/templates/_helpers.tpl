{{/*
Expand the name of the chart.
*/}}
{{- define "nixon-monitoring-resources.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nixon-monitoring-resources.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nixon-monitoring-resources.labels" -}}
helm.sh/chart: {{ include "nixon-monitoring-resources.chart" . }}
{{ include "nixon-monitoring-resources.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nixon-monitoring-resources.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nixon-monitoring-resources.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nixon-monitoring-resources.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nixon-monitoring-resources.name" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
