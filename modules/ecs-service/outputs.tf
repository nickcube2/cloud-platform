output "alb_dns_name" {
  description = "ALB DNS name — the public endpoint for the service"
  value       = aws_lb.this.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.this.name
}

output "task_execution_role_arn" {
  description = "Task execution role ARN"
  value       = aws_iam_role.task_execution.arn
}

output "log_group_name" {
  description = "CloudWatch log group for container logs"
  value       = aws_cloudwatch_log_group.app.name
}