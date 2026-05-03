output "plan_role_arn" {
  description = "ARN of the GitHub Actions plan role"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "ARN of the GitHub Actions apply role"
  value       = aws_iam_role.apply.arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = local.oidc_provider_arn
}