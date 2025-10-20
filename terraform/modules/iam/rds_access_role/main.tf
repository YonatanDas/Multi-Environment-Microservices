############################################
# IAM Role for RDS Access via IRSA
############################################
resource "aws_iam_role" "rds_access_role" {
  name = "${var.environment}-rds-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # ✅ FIXED: no "https://" prefix here
            "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })
}

############################################
# IAM Policy for Secrets Manager Read
############################################
resource "aws_iam_role_policy" "rds_secrets_access" {
  name = "rds-secretsmanager-access"
  role = aws_iam_role.rds_access_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = var.db_secret_arn
      }
    ]
  })
}
