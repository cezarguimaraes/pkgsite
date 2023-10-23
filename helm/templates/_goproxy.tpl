{{- define "pkgsite.goproxy" }}
{{- $athens := index .Values "athens-proxy" }}
{{- if $athens.enabled }}
{{- $athensChart := dict "Name" "athens-proxy" }}
{{- $athensCtx := dict "Values" $athens "Release" $.Release "Chart" $athensChart -}}
http://{{- template "fullname" $athensCtx }}.{{ $.Release.Namespace }}.svc.cluster.local
{{- else -}}
{{ $.Values.goproxy }}
{{- end }}
{{- end}}
