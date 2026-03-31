provider "aws" {
  region = "eu-west-1"
}

locals {
  name        = "myapp"
  environment = "staging"

  tags = {
    Environment = local.environment
    Project     = local.name
    ManagedBy   = "terraform"
  }
}

# --- Networking ---
module "vpc" {
  source = "../../modules/vpc"

  name               = local.name
  vpc_cidr           = "10.0.0.0/16"
  az_count           = 2
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_flow_logs   = true
  tags               = local.tags
}

# --- Database ---
module "rds" {
  source = "../../modules/rds-postgres"

  name                       = local.name
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.ecs.service_security_group_id]
  database_name              = "myapp"
  master_password            = var.db_password
  instance_class             = "db.t3.micro"
  multi_az                   = false
  deletion_protection        = false
  skip_final_snapshot        = true
  tags                       = local.tags
}

# --- Application ---
module "ecs" {
  source = "../../modules/ecs-fargate"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  container_image    = "nginx:alpine"
  container_port     = 80
  task_cpu           = 256
  task_memory        = 512
  desired_count      = 2
  enable_alb         = true
  health_check_path  = "/"

  environment_variables = {
    DB_HOST = module.rds.address
    DB_PORT = tostring(module.rds.port)
    DB_NAME = module.rds.database_name
  }

  tags = local.tags
}

# --- Static Assets ---
module "static" {
  source = "../../modules/s3-cloudfront"

  bucket_name       = "${local.name}-static-${local.environment}"
  enable_cloudfront = true
  tags              = local.tags
}

# --- IAM ---
module "iam" {
  source = "../../modules/iam-roles"

  name              = local.name
  create_cicd_role  = true
  github_org        = "g-holali-david"
  create_admin_role = false
  s3_bucket_arns    = [module.static.bucket_arn, "${module.static.bucket_arn}/*"]
  tags              = local.tags
}

# --- Variables ---
variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# --- Outputs ---
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns" {
  value = module.ecs.alb_dns_name
}

output "cloudfront_domain" {
  value = module.static.cloudfront_domain_name
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}
