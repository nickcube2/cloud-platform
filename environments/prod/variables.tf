variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "cloud-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}