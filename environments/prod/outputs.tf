output "app_url" {
  description = "Application URL"
  value       = "http://${module.app.alb_dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.app.ecs_cluster_name
}

output "log_group" {
  description = "CloudWatch log group"
  value       = module.app.log_group_name
}

output "plan_role_arn" {
  description = "GitHub Actions plan role ARN"
  value       = module.iam_oidc.plan_role_arn
}

output "apply_role_arn" {
  description = "GitHub Actions apply role ARN"
  value       = module.iam_oidc.apply_role_arn
}