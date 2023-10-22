{{- define "pkgsite.postgresql.host" -}}
{{- $postgres := index .Values "postgresql" }}
{{- $postgresChart := dict "Name" "postgresql" }}
{{- $postgresCtx := dict "Values" $postgres "Release" $.Release "Chart" $postgresChart -}}
{{ include "postgresql.v1.primary.fullname" $postgresCtx }}.{{ $.Release.Namespace }}
{{- end }}

{{- define "pkgsite.postgresql.password.secret" -}}
{{- $postgres := index .Values "postgresql" }}
{{- $postgresChart := dict "Name" "postgresql" }}
{{- $postgresCtx := dict "Values" $postgres "Release" $.Release "Chart" $postgresChart -}}
{{ include "common.names.fullname" $postgresCtx }}
{{- end }}
