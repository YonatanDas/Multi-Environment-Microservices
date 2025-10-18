output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "ecr_repository_urls" {
  description = "All created ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "eks_cluster_role_arn" {
  value = module.iam_cluster_role.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  value = module.iam_node_role.eks_node_role_arn
}
