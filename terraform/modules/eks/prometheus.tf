##########################################
# Monitoring Namespace
##########################################
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
  timeouts {
    delete = "5m"
  }
}

##########################################
# Prometheus Operator via Helm
##########################################

resource "helm_release" "prometheus_operator" {
  name       = "kube-prometheus-stack"
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.0.0"


  create_namespace = false

  values = [
    yamlencode({
      prometheusOperator = {
        admissionWebhooks = {
          enabled = false
        }
      }
      # Disable Alertmanager to free up pod slots
      alertmanager = {
        enabled = false
      }
      prometheus = {
        prometheusSpec = {
          retention = "15d"
        }
      }
      grafana = {
        adminPassword = "admin123"  # Simple password
        service = {
          type = "ClusterIP"
        }
        persistence = {
          enabled = false
        }
      }
    })
  ]

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.default,
    helm_release.kyverno
  ]

  atomic          = false
  cleanup_on_fail = false
  wait            = false   # Don't wait - deploy and configure later
  timeout         = 300
  wait_for_jobs   = false
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = "admin123"
  sensitive   = true
}