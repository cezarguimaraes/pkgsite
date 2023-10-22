{{- define "pkgsite.redis.host" -}}
{{- $redis := index .Values "redis" }}
{{- $redisChart := dict "Name" "redis" }}
{{- $redisCtx := dict "Values" $redis "Release" $.Release "Chart" $redisChart -}}
{{ printf "%s-master" (include "common.names.fullname" $redisCtx) }}.{{ $.Release.Namespace }}
{{- end }}

