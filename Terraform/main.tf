# Configure the AWS provider block. This tells Terraform which cloud provider to use and 
# how to authenticate (access key, secret key, and region) when provisioning resources.
# Note: Hardcoding credentials is not recommended for production use.
# Instead, use environment variables or IAM roles to manage credentials securely.
# Indicating Provider for Terraform to use
provider "aws" {
  access_key = var.aws_access_key        # Replace with your AWS access key ID (leave empty if using IAM roles or env vars)
  secret_key = var.aws_secret_key        # Replace with your AWS secret access key (leave empty if using IAM roles or env vars)
  region     = var.region           # Specify the AWS region where resources will be created (e.g., us-east-1, us-west-2)
}

module "VPC" {
  source = "./modules/VPC"
}

module "ALB" {
  source = "./modules/ALB"
  wl6vpc_id = module.VPC.wl6vpc_id
  public_subnet_1_id = module.VPC.public_subnet_1_id
  public_subnet_2_id = module.VPC.public_subnet_2_id
  app1 = module.EC2.app1
  app2 = module.EC2.app2
}

module "EC2" {
  source = "./modules/EC2"
  wl6vpc_id = module.VPC.wl6vpc_id
  public_subnet_1_id = module.VPC.public_subnet_1_id
  public_subnet_2_id = module.VPC.public_subnet_2_id
  private_subnet_1_id = module.VPC.private_subnet_1_id
  private_subnet_2_id = module.VPC.private_subnet_2_id
  nat_gateway_1 = module.VPC.nat_gateway_1
  nat_gateway_2 = module.VPC.nat_gateway_2
  # public_key_path = var.public_key_path
  rds_endpoint = module.RDS.rds_endpoint
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  rds_db = module.RDS.rds_db
  dockerhub_username = var.dockerhub_username
  dockerhub_password = var.dockerhub_password
}

module "RDS" {
  source = "./modules/RDS/"
  wl6vpc_id = module.VPC.wl6vpc_id
  app_sg = module.EC2.app_sg
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  private_subnet_1_id = module.VPC.private_subnet_1_id
  private_subnet_2_id = module.VPC.private_subnet_2_id
}