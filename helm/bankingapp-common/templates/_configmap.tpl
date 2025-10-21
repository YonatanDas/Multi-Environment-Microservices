{{- define "common.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.global.configMapName | default "bankingapp-config" }}
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
data:
  # ----- Spring Boot Environment -----
  SPRING_PROFILES_ACTIVE: {{ .Values.global.springProfile | default "default" }}

  # ----- Optional OpenTelemetry -----
  JAVA_TOOL_OPTIONS: {{ .Values.global.javaToolOptions | default "" }}
  OTEL_EXPORTER_OTLP_ENDPOINT: {{ .Values.global.otelExporterEndpoint | default "" }}
  OTEL_METRICS_EXPORTER: {{ .Values.global.otelMetricsExporter | default "none" }}
  OTEL_LOGS_EXPORTER: {{ .Values.global.otelLogsExporter | default "none" }}
{{- end -}}
