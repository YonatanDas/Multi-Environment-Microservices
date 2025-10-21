{{- define "common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.serviceName }}
  labels:
    app: {{ .Values.appLabel }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  selector:
    app: {{ .Values.appLabel }}
  ports:
    - port: {{ .Values.servicePort }}
      targetPort: {{ .Values.containerPort }}
      protocol: TCP
{{- end -}}
