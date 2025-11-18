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
  egress:
    # Allow calling sibling microservices
    - to:
        {{- range .Values.networkpolicy.allowToServices }}
        - podSelector:
            matchLabels:
              app: {{ . }}
        {{- end }}
      ports:
        - protocol: TCP
          port: {{ .Values.servicePort }}

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