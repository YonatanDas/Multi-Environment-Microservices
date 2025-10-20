output "rds_access_role_arn" {
  description = "IAM role ARN for RDS access via IRSA"
  value       = aws_iam_role.rds_access_role.arn
}

#output "oidc_provider_arn" {
 # description = "OIDC provider ARN"
  #value       = aws_iam_openid_connect_provider.eks.arn
#}
