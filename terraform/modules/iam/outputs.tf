output "eks_cluster_role_arn" {
  value = module.cluster_role.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  value = module.node_role.eks_node_role_arn
}

output "rds_access_role_arn" {
  description = "ARN of IAM role that grants EKS pods access to RDS secrets"
  value       = aws_iam_role.rds_access_role.arn
}

output "eso_role_arn" {
  description = "IAM Role ARN for External Secrets Operator"
  value       = aws_iam_role.eso_role.arn
}
