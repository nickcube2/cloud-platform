terraform {
  backend "s3" {
    bucket         = "cloud-platform-terraform-state-405449137534"
    key            = "environments/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloud-platform-terraform-locks"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:405449137534:key/219e066b-2285-4d37-9106-17e6795b0942"
    profile        = "cloud-platform"
  }
}