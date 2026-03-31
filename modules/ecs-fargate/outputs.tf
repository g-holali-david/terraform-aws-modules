output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "Task definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = var.enable_alb ? aws_lb.this[0].dns_name : ""
}

output "alb_arn" {
  description = "ALB ARN"
  value       = var.enable_alb ? aws_lb.this[0].arn : ""
}

output "task_role_arn" {
  description = "Task IAM role ARN (attach additional policies here)"
  value       = aws_iam_role.task.arn
}

output "execution_role_arn" {
  description = "Execution IAM role ARN"
  value       = aws_iam_role.execution.arn
}

output "service_security_group_id" {
  description = "Security group ID of the ECS service"
  value       = aws_security_group.service.id
}
