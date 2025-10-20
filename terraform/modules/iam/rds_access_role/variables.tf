##########################################
# Variables for IAM OIDC module
##########################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL"
  type        = string
}

variable "oidc_issuer_url" {
  description = "EKS OIDC issuer URL"
  type        = string  
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for RDS credentials"
  type        = string
}

variable "secrets_manager_arn" {
  description = "Secrets Manager ARN for RDS credentials"
  type        = string  
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account name"
  type        = string
  
}