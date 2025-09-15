output "ecs_service_id" {
  value       = join("", aws_ecs_service.default.*.id)
  description = "The Amazon Resource Name (ARN) that identifies the service."
}

output "ecs_service_name" {
  value       = join("", aws_ecs_service.default.*.name)
  description = "The name of the service."
}

output "ecs_service_cluster" {
  value       = join("", aws_ecs_service.default.*.cluster)
  description = "The Amazon Resource Name (ARN) of cluster which the service runs on."
}

output "ecs_service_iam_role" {
  value       = join("", aws_ecs_service.default.*.iam_role)
  description = "The ARN of IAM role used for ELB."
}

output "ecs_service_desired_count" {
  value       = join("", aws_ecs_service.default.*.desired_count)
  description = "The number of instances of the task definition."
}

output "security_group_id" {
  value       = join("", aws_security_group.default.*.id)
  description = "The ID of the ECS Service security group."
}

output "security_group_arn" {
  value       = join("", aws_security_group.default.*.arn)
  description = "The ARN of the ECS Service security group."
}

output "security_group_vpc_id" {
  value       = join("", aws_security_group.default.*.vpc_id)
  description = "The VPC ID of the ECS Service security group."
}

output "security_group_owner_id" {
  value       = join("", aws_security_group.default.*.owner_id)
  description = "The owner ID of the ECS Service security group."
}

output "security_group_name" {
  value       = join("", aws_security_group.default.*.name)
  description = "The name of the ECS Service security group."
}

output "security_group_description" {
  value       = join("", aws_security_group.default.*.description)
  description = "The description of the ECS Service security group."
}

output "security_group_ingress" {
  value       = flatten(aws_security_group.default.*.ingress)
  description = "The ingress rules of the ECS Service security group."
}

output "security_group_egress" {
  value       = flatten(aws_security_group.default.*.egress)
  description = "The egress rules of the ECS Service security group."
}

output "ecs_task_definition_arn" {
  value       = join("", aws_ecs_task_definition.default.*.arn)
  description = "Full ARN of the Task Definition (including both family and revision)."
}

output "ecs_task_definition_family" {
  value       = join("", aws_ecs_task_definition.default.*.family)
  description = "The family of the Task Definition."
}

output "ecs_task_definition_revision" {
  value       = join("", aws_ecs_task_definition.default.*.revision)
  description = "The revision of the task in a particular family."
}

output "iam_role_arn" {
  value       = join("", aws_iam_role.default.*.arn)
  description = "The Amazon Resource Name (ARN) specifying the IAM Role."
}

output "iam_role_create_date" {
  value       = join("", aws_iam_role.default.*.create_date)
  description = "The creation date of the IAM Role."
}

output "iam_role_unique_id" {
  value       = join("", aws_iam_role.default.*.unique_id)
  description = "The stable and unique string identifying the IAM Role."
}

output "iam_role_name" {
  value       = join("", aws_iam_role.default.*.name)
  description = "The name of the IAM Role."
}

output "iam_role_description" {
  value       = join("", aws_iam_role.default.*.description)
  description = "The description of the IAM Role."
}

output "iam_policy_id" {
  value       = join("", aws_iam_policy.default.*.id)
  description = "The IAM Policy's ID."
}

output "iam_policy_arn" {
  value       = join("", aws_iam_policy.default.*.arn)
  description = "The ARN assigned by AWS to this IAM Policy."
}

output "iam_policy_description" {
  value       = join("", aws_iam_policy.default.*.description)
  description = "The description of the IAM Policy."
}

output "iam_policy_name" {
  value       = join("", aws_iam_policy.default.*.name)
  description = "The name of the IAM Policy."
}

output "iam_policy_path" {
  value       = join("", aws_iam_policy.default.*.path)
  description = "The path of the IAM Policy."
}

output "iam_policy_document" {
  value       = join("", aws_iam_policy.default.*.policy)
  description = "The policy document of the IAM Policy."
}

# Auto Scaling Outputs
output "autoscaling_target_resource_id" {
  value       = join("", aws_appautoscaling_target.ecs_target.*.resource_id)
  description = "The resource ID of the auto-scaling target."
}

output "autoscaling_target_scalable_dimension" {
  value       = join("", aws_appautoscaling_target.ecs_target.*.scalable_dimension)
  description = "The scalable dimension of the auto-scaling target."
}

output "autoscaling_target_service_namespace" {
  value       = join("", aws_appautoscaling_target.ecs_target.*.service_namespace)
  description = "The service namespace of the auto-scaling target."
}

output "autoscaling_target_min_capacity" {
  value       = join("", aws_appautoscaling_target.ecs_target.*.min_capacity)
  description = "The minimum capacity of the auto-scaling target."
}

output "autoscaling_target_max_capacity" {
  value       = join("", aws_appautoscaling_target.ecs_target.*.max_capacity)
  description = "The maximum capacity of the auto-scaling target."
}

output "cloudwatch_log_group_name" {
  value       = join("", aws_cloudwatch_log_group.ecs_service.*.name)
  description = "The name of the CloudWatch log group."
}

output "cloudwatch_log_group_arn" {
  value       = join("", aws_cloudwatch_log_group.ecs_service.*.arn)
  description = "The ARN of the CloudWatch log group."
}
