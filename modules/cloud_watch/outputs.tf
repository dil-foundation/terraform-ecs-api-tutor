output "log_group_name" {
  value       = aws_cloudwatch_log_group.ecs-log-group.name
  description = "The Cloud watch log group name"
}