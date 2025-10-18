output "eks_node_role_arn" {
  description = "ARN of EKS node IAM role"
  value       = aws_iam_role.eks_node_role.arn
}
