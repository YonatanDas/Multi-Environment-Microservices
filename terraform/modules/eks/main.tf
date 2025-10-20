##########################################
# EKS Cluster and Node Group Definition
##########################################

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = concat(var.private_subnets, var.public_subnets)
  }

  # Control Plane Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

##########################################
# EKS Node Group
##########################################

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = var.node_desired_capacity
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"

  tags = {
    Name        = "${var.cluster_name}-node"
    Environment = var.environment
  }

  depends_on = [aws_eks_cluster.this]
}

##########################################
# Create OIDC provider for IRSA
##########################################

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd50b3b"] # standard for EKS OIDC
  url             = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

##########################################
# Data Source: Cluster Authentication
##########################################

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

