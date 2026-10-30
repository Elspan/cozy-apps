{{/*
Public hostname: the host value, or <release name>.<tenant host>. Cozystack
injects the tenant host as .Values._namespace.host through the cozystack-values
secret. Same rule as cozy-lib.ns-host-required: fail when the platform injected
an empty tenant host and no override is set, rather than render "<name>.".
*/}}
{{- define "vaultwarden.host" -}}
{{- $ns := .Values._namespace -}}
{{- $apex := ($ns | default dict).host | default "" -}}
{{- if and $ns (not .Values.host) (not $apex) -}}
{{- fail "the tenant host (_namespace.host) is empty and this app sets no host, so its hostname would be malformed. Set tenant.spec.host on this tenant or a parent, or set this app's host value." -}}
{{- end -}}
{{- .Values.host | default (printf "%s.%s" .Release.Name $apex) -}}
{{- end }}

{{- define "vaultwarden.selectorLabels" -}}
app.kubernetes.io/name: vaultwarden
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
RBAC subjects with admin access or above to this tenant or any of its parents.
Inlines cozy-lib.rbac.subjectsForTenantAndAccessLevel (list "admin" ns).
*/}}
{{- define "vaultwarden.adminSubjects" -}}
{{- $namespace := .Release.Namespace }}
{{- if not (hasPrefix "tenant-" $namespace) }}
{{- fail (printf "'%s' is not a tenant namespace" $namespace) }}
{{- end }}
{{- $parts := append (splitList "-" $namespace) "" }}
{{- $tenants := list }}
{{- range untilStep 2 (len $parts) 1 }}
{{- $tenants = append $tenants (slice $parts 0 . | join "-") }}
{{- end }}
{{- if ne $namespace "tenant-root" }}
{{- $tenants = append $tenants "tenant-root" }}
{{- end }}
{{- range $tenant := $tenants }}
- kind: ServiceAccount
  name: {{ $tenant }}
  namespace: {{ $tenant }}
{{- range list "admin" "super-admin" }}
- kind: Group
  name: {{ $tenant }}-{{ . }}
  apiGroup: rbac.authorization.k8s.io
{{- end }}
{{- end }}
{{- end }}
