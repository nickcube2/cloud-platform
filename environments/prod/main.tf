terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "cloud-platform"
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = "${var.project}-${var.environment}"
  cidr_block           = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  nat_gateway_count    = 1
  enable_flow_logs     = true

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

module "app" {
  source = "../../modules/ecs-service"

  name               = "${var.project}-${var.environment}-app"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  container_image   = "nginx:latest"
  container_port    = 80
  health_check_path = "/"
  task_cpu          = 256
  task_memory       = 512
  desired_count     = 2

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}