locals {
  name_prefix = "bankingapp-${var.environment}"
}

module "vpc" {
  source              = "../../modules/vpc"
  environment                 = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "ecr" {
  source        = "../../modules/ecr"
  service_names = ["accounts", "cards", "loans", "configserver", "gateway"]
  environment   = var.environment
}


module "eks" {
  source = "../../modules/eks"

  # identifiers
  cluster_name = var.cluster_name
  environment  = var.environment

  # networking
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets

  # IAM
  cluster_role_arn = module.iam_cluster_role.eks_cluster_role_arn
  node_role_arn    = module.iam_node_role.eks_node_role_arn
  oidc_provider_arn = module.eks.oidc_provider_arn

  # node group settings
  node_instance_type    = "t3.medium"
  node_desired_capacity = 2
}


module "iam_cluster_role" {
  source      = "../../modules/iam/cluster_role"
  name_prefix = "banking"
}

module "iam_node_role" {
  source      = "../../modules/iam/node_role"
  name_prefix = "banking"
}

# Secrets Manager for DB credentials
module "secrets" {
  source      = "../../modules/secrets"
  environment         = var.environment
  db_username = "dbadmin"
  db_password = random_password.db.result
  aws_secretsmanager_secret_arn = module.secrets.db_secret_arn
}


module "iam_rds_access_role" {
  source                = "../../modules/iam/rds_access_role"
  oidc_provider_url     = module.eks.oidc_issuer_url
  cluster_name          = module.eks.cluster_name
  environment = var.environment
  namespace             = "default"
  service_account_name  = "rds-access"
    db_secret_arn        = module.secrets.db_secret_arn
    oidc_issuer_url =  module.eks.oidc_issuer_url
    oidc_provider_arn = module.eks.oidc_provider_arn
    secrets_manager_arn = module.secrets.db_secret_arn
}

# Generate a strong DB password once per environment
resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "_%-@"
}


# RDS Instance
module "rds" {
  source      = "../../modules/rds"
  environment         = var.environment
  subnet_ids  = module.vpc.private_subnets
  db_instance_class = "var.db_instance_class"
  db_username = "dbadmin"
  db_password = random_password.db.result
  db_sg_id    = module.vpc.rds_sg_id   
}

