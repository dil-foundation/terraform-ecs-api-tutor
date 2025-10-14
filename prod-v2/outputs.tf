output "cdn_url" {
  description = "CloudFront distribution URL"
  value       = module.cloudfront.cloudfront_dns_record
}

# API Gateway output removed - routing directly to ALB
# output "api_gateway_invoke_url" {
#   description = "API Gateway invoke URL"
#   value       = module.api_gateway.api_gateway_invoke_url
# }

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

# RDS endpoint removed - app uses MemoryDB

output "memorydb_endpoint" {
  description = "MemoryDB cluster endpoint"
  value       = local.enable_redis ? module.memorydb[0].cluster_endpoint : null
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.ecs-cluster.name
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = module.s3-bucket.s3_bucket_id
}

# Bastion SSH command removed - no RDS to access

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = data.aws_ecr_repository.existing.repository_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

