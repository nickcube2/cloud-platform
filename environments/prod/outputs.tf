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