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
  region  = "us-east-1"
  profile = "cloud-platform"
}

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption - cloud-platform"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name      = "cloud-platform-terraform-state"
    ManagedBy = "terraform"
    Project   = "cloud-platform"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/cloud-platform-terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "cloud-platform-terraform-state-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "cloud-platform-terraform-state"
    ManagedBy = "terraform"
    Project   = "cloud-platform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "cloud-platform-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name      = "cloud-platform-terraform-locks"
    ManagedBy = "terraform"
    Project   = "cloud-platform"
  }
}