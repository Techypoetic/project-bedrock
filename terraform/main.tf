# Local variables for consistent tagging
locals {
  common_tags = {
    Project     = "Bedrock"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  cluster_name = "${var.project_name}-cluster"
  vpc_name     = "${var.project_name}-vpc"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_name             = local.vpc_name
  vpc_cidr             = var.vpc_cidr
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false # Use one NAT per AZ for HA
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  cluster_name = local.cluster_name
  tags         = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name        = local.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  cluster_role_arn    = module.iam.cluster_role_arn
  node_group_role_arn = module.iam.node_group_role_arn

  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_instance_types = var.node_instance_types

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = local.common_tags
}
