{{- define "common.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.deploymentName }}
  labels:
    app: {{ .Values.appLabel }}
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/version: {{ .Chart.AppVersion }}
    helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.appLabel }}
  template:
    metadata:
      labels:
        app: {{ .Values.appLabel }}
    spec:
      serviceAccountName: {{ .Values.serviceAccount.name }}
      containers:
        - name: {{ .Values.appLabel }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: {{ .Values.containerPort }}
          env:
            # Core Spring Configs
            - name: SPRING_PROFILES_ACTIVE
              valueFrom:
                configMapKeyRef:
                  name: {{ .Values.global.configMapName }}
                  key: SPRING_PROFILES_ACTIVE

          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: {{ .Values.containerPort }}
            initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
            timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.liveness.failureThreshold }}

          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: {{ .Values.containerPort }}
            initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
            timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.readiness.failureThreshold }}

          {{- if .Values.resources }}
          
          resources:
            {{- toYaml .Values.resources | nindent 12 }}        
    
          {{- if .Values.dbSecretName }}

          # --- Database and AWS Secrets ---

          envFrom:
            - secretRef:
                name: {{ .Values.dbSecretName }}
          {{- end }}
          {{- end }}
{{- end -}}
