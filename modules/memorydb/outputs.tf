output "cluster_id" {
  description = "ID of the MemoryDB cluster"
  value       = var.enabled ? aws_memorydb_cluster.memorydb[0].id : null
}

output "cluster_endpoint" {
  description = "Endpoint address of the MemoryDB cluster"
  value       = var.enabled ? aws_memorydb_cluster.memorydb[0].cluster_endpoint[0].address : null
}

output "port" {
  description = "Port number of the MemoryDB cluster"
  value       = var.enabled ? aws_memorydb_cluster.memorydb[0].port : null
}

output "security_group_id" {
  description = "Security group ID of the MemoryDB cluster"
  value       = var.enabled ? aws_memorydb_cluster.memorydb[0].security_group_ids : null
}

output "subnet_group_name" {
  description = "Name of the MemoryDB subnet group"
  value       = var.enabled ? aws_memorydb_subnet_group.memorydb_subnet_group[0].name : null
}

output "parameter_group_name" {
  description = "Name of the MemoryDB parameter group"
  value       = var.enabled ? aws_memorydb_parameter_group.memorydb_parameter_group[0].name : null
}

output "arn" {
  description = "ARN of the MemoryDB cluster"
  value       = var.enabled ? aws_memorydb_cluster.memorydb[0].arn : null
}
