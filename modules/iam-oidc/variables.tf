variable "project" {
  description = "Project name — used in role naming"
  type        = string
}

variable "github_org" {
  description = "GitHub organisation or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "create_oidc_provider" {
  description = "Set false if the GitHub OIDC provider already exists in this account"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to merge onto all resources"
  type        = map(string)
  default     = {}
}
