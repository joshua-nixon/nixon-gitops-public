{{/*
Expand the name of the chart.
*/}}
{{- define "nixon-deployable.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nixon-deployable.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nixon-deployable.labels" -}}
helm.sh/chart: {{ include "nixon-deployable.chart" . }}
{{ include "nixon-deployable.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nixon-deployable.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nixon-deployable.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nixon-deployable.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nixon-deployable.name" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the persistence claim when managed by this chart.
*/}}
{{- define "nixon-deployable.persistenceClaimName" -}}
{{- tpl .Values.persistence.claimName . | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Build a semicolon-separated ASPNETCORE_URLS value from enabled containerPorts.
Returns empty string if no ports are enabled.
*/}}
{{- define "nixon-deployable.aspnetCoreUrlsEnvValue" -}}
{{- $ports := .Values.containerPorts }}
{{- $urls := list }}
{{- if $ports }}
{{- range $name, $port := $ports }}
  {{- if $port.enabled }}
    {{- $u := printf "http://+:%v" $port.containerPort }}
    {{- $urls = append $urls $u }}
  {{- end }}
{{- end }}
{{- end }}
{{- if gt (len $urls) 0 }}
{{- printf "%s" (join ";" $urls) }}
{{- end }}
{{- end }}

{{/*
Name of the ExternalName Service pointing at the KEDA HTTP add-on interceptor.
*/}}
{{- define "nixon-deployable.proxyServiceName" -}}
{{- include "nixon-deployable.name" . }}-proxy
{{- end }}

{{/*
Ingress backend Service name: the KEDA HTTP proxy when scale-to-zero is enabled, otherwise this app's own Service.
*/}}
{{- define "nixon-deployable.ingressServiceName" -}}
  {{- if .Values.interceptorRoute.enabled -}}
    {{- include "nixon-deployable.proxyServiceName" . -}}
  {{- else -}}
    {{- include "nixon-deployable.name" . -}}
  {{- end -}}
{{- end }}

{{/*
Render the selected securityContext preset as YAML
*/}}
{{- define "nixon-deployable.securityContext" -}}
{{- $preset := get .Values.securityContextPresets .Values.securityContextPreset | default dict -}}
{{- if and $preset (ne (len $preset) 0) -}}
{{ toYaml $preset }}
{{- end -}}
{{- end -}}