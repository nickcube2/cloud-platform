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