locals {
  tenant_name            = "dil-fnd"
  environment            = "dev"
  cidr_block             = "12.0.0.0/16"
  tf_remote_state_bucket = "dilf-dev-tf-remote-state-342834686411"

  # Cost saving flags
  enable_rds     = false # Set to false - using MemoryDB instead
  enable_bastion = false # Set to false since no direct RDS access needed
  enable_redis   = true  # Set to true to enable MemoryDB

  # Environment variables for AI Tutor Backend (from GitHub Secrets)
  supabase_url           = var.supabase_url
  supabase_service_key   = var.supabase_service_key
  openai_api_key         = var.openai_api_key
  eleven_api_key         = var.eleven_api_key
  eleven_voice_id        = var.eleven_voice_id
}

module "cloud_watch" {
  source = "../modules/cloud_watch"
  name   = local.tenant_name

  tags = {
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
  }
}

module "cloudfront" {
  source = "../modules/cloud_front"

  enable_route53_record = false

  environment = local.tenant_name
  name        = "${local.tenant_name}-cloud-front"

  load_balancer_arn      = module.alb.alb_arn
  bucket_id              = module.s3-bucket.s3_bucket_id
  origin_access_identity = module.s3-bucket.origin_access_identity
  enable_backend         = true

  # API Gateway configuration
  enable_api_gateway      = true
  api_gateway_domain_name = module.api_gateway.api_gateway_domain_name
  api_gateway_invoke_url  = module.api_gateway.api_gateway_invoke_url

  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0

  depends_on = [module.api_gateway]

  tags = {
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
    Updated     = "2025-09-02"
  }

  custom_error_response = [
    {
      "error_code"         = 403
      "response_code"      = 200
      "response_page_path" = "/index.html"
    },
    {
      "error_code"         = 404
      "response_code"      = 200
      "response_page_path" = "/index.html"
    },
  ]

  bucket_force_destroy = true
}

module "ecs_fargate" {
  source           = "../modules/ecs_fargate"
  name             = "${local.tenant_name}-task-definition"
  container_name   = local.container_name
  container_port   = local.container_port
  cluster          = aws_ecs_cluster.ecs-cluster.arn
  subnets          = module.vpc.public_subnet_ids
  target_group_arn = module.alb.alb_target_group_arn
  vpc_id           = module.vpc.vpc_id

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "342834686411.dkr.ecr.us-east-2.amazonaws.com/ai-tutor-backend:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.cloud_watch.log_group_name,
          awslogs-region        = "us-east-2",
          awslogs-stream-prefix = "${local.tenant_name}-app"
        }
      }
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        # Google Cloud Configuration
        { name = "GOOGLE_APPLICATION_CREDENTIALS", value = "/app/credentials/google-credentials.json" },
        
        # OpenAI Configuration
        { name = "OPENAI_API_KEY", value = local.openai_api_key },
        
        # Redis Configuration (for caching/sessions)
        { name = "REDIS_URL", value = local.enable_redis ? "redis://${module.memorydb[0].cluster_endpoint}:6379" : "redis://localhost:6379" },
        
        # ElevenLabs Configuration
        { name = "ELEVEN_API_KEY", value = local.eleven_api_key },
        
        # Supabase Configuration (main database)
        { name = "SUPABASE_URL", value = local.supabase_url },
        { name = "SUPABASE_ANON_KEY", value = local.supabase_service_key }
      ]
    }
  ])

  desired_count                      = 2
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller_type         = "ECS"
  assign_public_ip                   = true
  health_check_grace_period_seconds  = 10
  platform_version                   = "LATEST"
  source_cidr_blocks                 = ["0.0.0.0/0"]
  cpu                                = 1024
  memory                             = 4096
  requires_compatibilities           = ["FARGATE"]
  iam_path                           = "/service_role/"
  description                        = "This is ${local.tenant_name}-UAT"
  enabled                            = true

  create_ecs_task_execution_role = true
  ecs_task_execution_role_arn    = aws_iam_role.default.arn

  # Auto Scaling Configuration
  enable_autoscaling    = true
  min_capacity          = 1
  max_capacity          = 10
  cpu_target_value      = 70.0
  memory_target_value   = 80.0
  log_retention_in_days = 7

  tags = {
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
  }
}

resource "aws_iam_role" "default" {
  name               = "${local.tenant_name}-ecs-task-execution-for-ecs-fargate"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com", "ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "default" {
  name   = aws_iam_role.default.name
  policy = data.aws_iam_policy.ecs_task_execution.policy
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

data "aws_iam_policy" "ecs_task_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

locals {
  container_name = "${local.tenant_name}-service"
  container_port = tonumber(module.alb.alb_target_group_port)
  #host_port = tonumber(module.alb.http_port)
}

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${local.tenant_name}-ecs-cluster"
}

module "alb" {
  source                     = "../modules/alb"
  name                       = "${local.tenant_name}-fargate-lb-v2"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnet_ids
  access_logs_bucket         = module.s3_lb_log.s3_bucket_id
  enable_https_listener      = false
  enable_http_listener       = true
  enable_deletion_protection = false

  internal                    = false
  idle_timeout                = 120
  enable_http2                = false
  ip_address_type             = "ipv4"
  access_logs_prefix          = "test"
  access_logs_enabled         = true
  ssl_policy                  = "ELBSecurityPolicy-2016-08"
  https_port                  = 443
  http_port                   = 80
  fixed_response_content_type = "text/plain"
  fixed_response_message_body = "ok"
  fixed_response_status_code  = "200"
  source_cidr_blocks          = ["0.0.0.0/0"]

  target_group_port                = 8000
  target_group_protocol            = "HTTP"
  target_type                      = "ip"
  deregistration_delay             = 600
  slow_start                       = 0
  health_check_path                = "/health"
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 3
  health_check_timeout             = 10
  health_check_interval            = 30
  health_check_matcher             = "200-399"
  health_check_port                = "traffic-port"
  health_check_protocol            = "HTTP"
  listener_rule_priority           = 1
  listener_rule_condition_field    = "path-pattern"
  listener_rule_condition_values   = ["/*"]
  enabled                          = true

  tags = {
    Tenant      = "${local.tenant_name}"
    Environment = "${local.environment}"

  }
}

module "s3_lb_log" {
  source                = "../modules/s3_lb_log"
  name                  = "${local.tenant_name}-s3-lb-log-ecs-fargate-${data.aws_caller_identity.current.account_id}"
  logging_target_bucket = module.s3_access_log.s3_bucket_id
  force_destroy         = true
}

module "s3_access_log" {
  source        = "../modules/s3_access_log"
  name          = "${local.tenant_name}-s3-access-log-ecs-fargate-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

module "vpc" {
  source                     = "../modules/vpc"
  cidr_block                 = local.cidr_block
  name                       = "${local.tenant_name}-ecs-fargate"
  public_subnet_cidr_blocks  = [cidrsubnet(local.cidr_block, 8, 0), cidrsubnet(local.cidr_block, 8, 1)]
  public_availability_zones  = data.aws_availability_zones.available.names
  private_subnet_cidr_blocks = [cidrsubnet(local.cidr_block, 8, 2), cidrsubnet(local.cidr_block, 8, 3)]
  private_availability_zones = data.aws_availability_zones.available.names
  tags = {
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
  }
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

# RDS Module removed - using MemoryDB instead

# MemoryDB Module
module "memorydb" {
  count  = local.enable_redis ? 1 : 0
  source = "../modules/memorydb"

  name               = "${local.tenant_name}-memorydb"
  description        = "MemoryDB cluster for AI Tutor Backend"
  node_type          = "db.t4g.small"
  port               = 6379
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.memorydb_sg[0].id]
  engine_version     = "7.0"
  num_shards         = 1
  num_replicas_per_shard = 1

  tags = {
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
  }
}

# Security Group for MemoryDB
resource "aws_security_group" "memorydb_sg" {
  count       = local.enable_redis ? 1 : 0
  name        = "${local.tenant_name}-memorydb-sg"
  description = "Security group for MemoryDB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [local.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.tenant_name}-memorydb-sg"
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
  }
}

# Bastion host removed - no RDS to access

module "api_gateway" {
  source = "../modules/api_gateway"

  name        = "${local.tenant_name}-api-gateway"
  environment = local.environment
  tenant_name = local.tenant_name

  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id

  # VPC configuration for Lambda function
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.alb.security_group_id]

  stage_name     = "prod"
  enable_cors    = true
  enable_api_key = false

  throttle_rate_limit  = 1000
  throttle_burst_limit = 2000

  depends_on = [module.alb, module.ecs_fargate, module.vpc]
}

module "s3-terraform-remote-state" {
  source      = "../modules/s3-terraform-remote-state"
  bucket_name = local.tf_remote_state_bucket
}

module "s3-bucket" {
  source      = "../modules/s3"
  bucket_name = "${local.tenant_name}-admin-portal-${data.aws_caller_identity.current.account_id}"
  tags = {
    Environment = "${local.environment}"
    tenant      = "${local.tenant_name}"
  }
}

module "ecr" {
  source = "../modules/ecr"

  repository_name = "ai-tutor-api"
  
  tags = {
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
    Service     = "ai-tutor"
  }
}
# Backend configuration removed - using local state for dev





