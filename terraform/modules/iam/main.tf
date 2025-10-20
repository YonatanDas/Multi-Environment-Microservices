##########################################
# IAM Root Module - orchestrates submodules
##########################################

module "cluster_role" {
  source      = "./cluster_role"
  name_prefix = "${var.environment}-${var.cluster_name}"
}

module "node_role" {
  source      = "./node_role"
  name_prefix = "${var.environment}-${var.cluster_name}"
}

module "iam_rds_access_role" {
  source               = "./modules/iam/rds_access_role"
  oidc_provider_url    = module.eks.oidc_issuer_url
  cluster_name         = module.eks.cluster_name
  secretsmanager_arn   = module.secrets.db_secret_arn
  namespace            = "default"
  service_account_name = "rds-access"
}