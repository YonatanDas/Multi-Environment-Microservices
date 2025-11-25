{{- define "common.networkpolicy" -}}
{{- if .Values.networkpolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Chart.Name }}-network-policy
  labels:
    app: {{ .Chart.Name }}
spec:
  podSelector:
    matchLabels:
      app: {{ .Chart.Name }}

  policyTypes:
    - Ingress
    - Egress

  ingress:
  {{- if eq .Chart.Name "gateway" }}
  # Gateway: Allow traffic from anywhere (ALB/Ingress Controller)
  - {}
  {{- else }}
  # Allow traffic from gateway → this service
  - from:
      - podSelector:
          matchLabels:
            app: gateway
    ports:
      - protocol: TCP
        port: {{ .Values.servicePort }}

  # Allow traffic from sibling microservices
  {{- range $svc := .Values.networkpolicy.allowFromServices }}
  - from:
      - podSelector:
          matchLabels:
            app: {{ $svc }}
    ports:
      - protocol: TCP
        port: {{ index $.Values.networkpolicy.targetPorts $svc }}
  {{- end }}
  {{- end }}

  # ========== ADD THIS: Allow Prometheus scraping ==========
  - from:
      - namespaceSelector:
          matchLabels:
            name: monitoring
    ports:
      - protocol: TCP
        port: {{ .Values.containerPort }}
  # ========== END ==========

  egress:
    # Allow calling sibling microservices
    {{- if .Values.networkpolicy.allowToServices }}
    {{- range $svc := .Values.networkpolicy.allowToServices }}
    - to:
        - podSelector:
            matchLabels:
              app: {{ $svc }}
      ports:
        - protocol: TCP
          port: {{ index $.Values.networkpolicy.targetPorts $svc }}
    {{- end }}
    {{- end }}

    # ========== ADD THIS: Allow egress to monitoring ==========
    - to:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - protocol: TCP
          port: 4317  # OTLP gRPC
        - protocol: TCP
          port: 4318  # OTLP HTTP
        - protocol: TCP
          port: 3100  # Loki
    # ========== END ==========

    # Allow DNS + external APIs + External Secrets Operator
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 443
{{- end }}
{{- end }}