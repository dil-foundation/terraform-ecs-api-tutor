locals {
  tenant_name            = "dil-prod-v2"
  environment            = "prod"
  cidr_block             = "12.0.0.0/16"
  tf_remote_state_bucket = "dil-prod-terraform-state"

  # Cost saving flags
  enable_rds     = false # Set to false - using MemoryDB instead
  enable_bastion = false # Set to false since no direct RDS access needed
  enable_redis   = true  # Set to true to enable MemoryDB

  # Environment variables for AI Tutor Backend (from GitHub Secrets)
  supabase_url         = var.supabase_url
  supabase_service_key = var.supabase_service_key
  openai_api_key       = var.openai_api_key
  eleven_api_key       = var.eleven_api_key
  eleven_voice_id      = var.eleven_voice_id


  # WordPress Configuration (from GitHub Secrets)
  wp_site_url                 = var.wp_site_url
  wp_api_username             = var.wp_api_username
  wp_api_application_password = var.wp_api_application_password
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

  # API Gateway configuration - DISABLED (routing directly to ALB)
  enable_api_gateway      = false
  api_gateway_domain_name = ""
  api_gateway_invoke_url  = ""

  # Domain names for production environment only
  aliases = local.environment == "prod" ? ["learn.dil.org", "www.learn.dil.org"] : []
  ssl_certificate_arn = local.environment == "prod" ? var.ssl_certificate_arn : ""

  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0

  # depends_on = [module.api_gateway]  # Removed - no longer using API Gateway

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
  name             = "${local.tenant_name}-ai-tutor-service-v2"
  container_name   = local.container_name
  container_port   = local.container_port
  cluster          = aws_ecs_cluster.ecs-cluster.arn
  subnets          = module.vpc.private_subnet_ids
  target_group_arn = module.alb.alb_target_group_arn
  vpc_id           = module.vpc.vpc_id

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${data.aws_ecr_repository.existing.repository_url}:${var.ai-tutor_image_tag}"
      essential = true
      cpu       = 4096
      memory    = 30720
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
        # OpenAI Configuration
        { name = "OPENAI_API_KEY", value = local.openai_api_key },

        # ElevenLabs Configuration
        { name = "ELEVEN_API_KEY", value = local.eleven_api_key },
        { name = "ELEVEN_VOICE_ID", value = local.eleven_voice_id },

        # Supabase Configuration (main database)
        { name = "SUPABASE_URL", value = local.supabase_url },
        { name = "SUPABASE_SERVICE_KEY", value = local.supabase_service_key },

        # WordPress Configuration
        { name = "WP_SITE_URL", value = local.wp_site_url },
        { name = "WP_API_USERNAME", value = local.wp_api_username },
        { name = "WP_API_APPLICATION_PASSWORD", value = local.wp_api_application_password },

        # Redis Configuration (AWS MemoryDB with password authentication and TLS)
        { name = "REDIS_URL", value = local.enable_redis ? "rediss://default-user:RedisSecurePassword2024!@${module.memorydb[0].cluster_endpoint}:6379" : "redis://localhost:6379" },
        { name = "REDIS_HOST", value = local.enable_redis ? module.memorydb[0].cluster_endpoint : "localhost" },
        { name = "REDIS_PORT", value = "6379" },
        { name = "REDIS_USERNAME", value = local.enable_redis ? "default-user" : "" },
        { name = "REDIS_PASSWORD", value = local.enable_redis ? "RedisSecurePassword2024!" : "" },
        { name = "REDIS_USE_TLS", value = local.enable_redis ? "true" : "false" },

        # Application Environment
        { name = "ENVIRONMENT", value = "production" },

        # Task definition version identifier to force updates
        { name = "TASK_VERSION", value = "v2.0-2vcpu-16gb-20250921" }
      ]

      # Add secrets for Google credentials
      secrets = [
        {
          name      = "GOOGLE_APPLICATION_CREDENTIALS_JSON"
          valueFrom = aws_secretsmanager_secret.google_credentials.arn
        }
      ]
    }
  ])

  desired_count                      = 2
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller_type         = "ECS"
  assign_public_ip                   = false
  health_check_grace_period_seconds  = 300
  platform_version                   = "LATEST"
  source_cidr_blocks                 = ["0.0.0.0/0"]
  cpu                                = 2048
  memory                             = 16384
  requires_compatibilities           = ["FARGATE"]
  iam_path                           = "/service_role/"
  description                        = "This is ${local.tenant_name}-UAT"
  enabled                            = true

  create_ecs_task_execution_role = false
  ecs_task_execution_role_arn    = aws_iam_role.default.arn
  ecs_task_role_arn              = aws_iam_role.task_role.arn

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
    Version     = "v2.0-2vcpu-16gb"
    LastUpdated = "2025-09-21"
  }
}

# ECS Fargate service for db-mcp-server
module "ecs_fargate_db_mcp" {
  source           = "../modules/ecs_fargate"
  name             = "${local.tenant_name}-db-mcp-server"
  container_name   = local.db_mcp_container_name
  container_port   = local.db_mcp_container_port
  cluster          = aws_ecs_cluster.ecs-cluster.arn
  subnets          = module.vpc.private_subnet_ids
  target_group_arn = aws_lb_target_group.db_mcp.arn
  vpc_id           = module.vpc.vpc_id

  container_definitions = jsonencode([
    {
      name      = local.db_mcp_container_name
      image     = "342834686411.dkr.ecr.us-east-2.amazonaws.com/db-mcp-server:${var.db_mcp_server_tag}"
      essential = true
      cpu       = 512
      memory    = 1024
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.cloud_watch.log_group_name,
          awslogs-region        = "us-east-2",
          awslogs-stream-prefix = "${local.tenant_name}-db-mcp"
        }
      }
      portMappings = [
        {
          containerPort = 8001
          protocol      = "tcp"
        }
      ]
      environment = [
        # Database Configuration
        { name = "DATABASE_URL", value = var.database_url },
        
        # Application Environment
        { name = "ENVIRONMENT", value = "production" },
        { name = "MCP_HTTP_HOST", value = "0.0.0.0" },
        { name = "MCP_HTTP_PORT", value = "8001" },
        { name = "MCP_USER_IDENTITY", value = "navee" },

        # Task definition version identifier to force updates
        { name = "TASK_VERSION", value = "v1.0-db-mcp-20250923" }
      ]
    }
  ])

  desired_count                      = 2
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller_type         = "ECS"
  assign_public_ip                   = false
  health_check_grace_period_seconds  = 300
  platform_version                   = "LATEST"
  source_cidr_blocks                 = ["0.0.0.0/0"]
  cpu                                = 512
  memory                             = 1024
  requires_compatibilities           = ["FARGATE"]
  iam_path                           = "/service_role/"
  description                        = "This is ${local.tenant_name} db-mcp-server"
  enabled                            = true

  create_ecs_task_execution_role = false
  ecs_task_execution_role_arn    = aws_iam_role.default.arn
  ecs_task_role_arn              = aws_iam_role.task_role.arn

  # Auto Scaling Configuration
  enable_autoscaling    = true
  min_capacity          = 1
  max_capacity          = 5
  cpu_target_value      = 70.0
  memory_target_value   = 80.0
  log_retention_in_days = 7

  tags = {
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
    Service     = "db-mcp-server"
  }
}

# ECS Task Execution Role (for pulling images, writing logs)
resource "aws_iam_role" "default" {
  name               = "${local.tenant_name}-ecs-task-execution-for-ecs-fargate"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# ECS Task Role (for container applications to access AWS services)
resource "aws_iam_role" "task_role" {
  name               = "${local.tenant_name}-ecs-task-role-for-ecs-fargate"
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

resource "aws_iam_policy" "ecs_task_execution" {
  name   = "${aws_iam_role.default.name}-ecs-execution"
  policy = data.aws_iam_policy.ecs_task_execution.policy
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.ecs_task_execution.arn
}

data "aws_iam_policy" "ecs_task_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM policies removed - using password authentication instead of IAM

# AWS Secrets Manager for Google Credentials
resource "aws_secretsmanager_secret" "google_credentials" {
  name        = "${local.tenant_name}-google-credentials"
  description = "Google Cloud Service Account credentials for AI Tutor"

  tags = {
    Environment = local.environment
    Tenant      = local.tenant_name
  }
}

resource "aws_secretsmanager_secret_version" "google_credentials" {
  secret_id     = aws_secretsmanager_secret.google_credentials.id
  secret_string = var.google_credentials_json
}

# Additional IAM policy for accessing secrets and CloudWatch logs
resource "aws_iam_policy" "secrets_access" {
  name        = "${local.tenant_name}-ecs-secrets-access"
  description = "Policy to allow ECS tasks to access secrets and CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "${aws_secretsmanager_secret.google_credentials.arn}*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:us-east-2:*:log-group:/ecs/${local.tenant_name}-ai-tutor-service-v2*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# Additional policy for ECS Exec
resource "aws_iam_policy" "ecs_exec" {
  name        = "${local.tenant_name}-ecs-exec-policy"
  description = "Policy to allow ECS Exec functionality"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.ecs_exec.arn
}


locals {
  container_name = "${local.tenant_name}-ai-tutor-container-v2"
  container_port = tonumber(module.alb.alb_target_group_port)
  #host_port = tonumber(module.alb.http_port)
  
  # db-mcp-server container configuration
  db_mcp_container_name = "${local.tenant_name}-db-mcp-container"
  db_mcp_container_port = 8001
}

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${local.tenant_name}-ecs-fargate-cluster-v2"
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
  health_check_unhealthy_threshold = 10
  health_check_timeout             = 30
  health_check_interval            = 60
  health_check_matcher             = "200-399"
  health_check_port                = "traffic-port"
  health_check_protocol            = "HTTP"
  listener_rule_priority           = 200
  listener_rule_condition_field    = "path-pattern"
  listener_rule_condition_values   = ["/*"]
  enabled                          = true

  tags = {
    Tenant      = "${local.tenant_name}"
    Environment = "${local.environment}"

  }
}

# Target Group for db-mcp-server
resource "aws_lb_target_group" "db_mcp" {
  name     = "${local.tenant_name}-db-mcp-tg"
  port     = 8001
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 15
    interval            = 30
    path                = "/"
    matcher             = "200-399"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "${local.tenant_name}-db-mcp-tg"
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
    Service     = "db-mcp-server"
  }
}

# Listener Rule for /chat endpoints to route to db-mcp-server
resource "aws_lb_listener_rule" "db_mcp_chat" {
  listener_arn = module.alb.http_alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db_mcp.arn
  }

  condition {
    path_pattern {
      values = ["/chat", "/chat/*"]
    }
  }

  tags = {
    Name        = "${local.tenant_name}-db-mcp-chat-rule"
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
    Service     = "db-mcp-server"
  }
}

# Listener Rule for /mcp endpoints to route to db-mcp-server
resource "aws_lb_listener_rule" "db_mcp_protocol" {
  listener_arn = module.alb.http_alb_listener_arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db_mcp.arn
  }

  condition {
    path_pattern {
      values = ["/mcp", "/mcp/*"]
    }
  }

  tags = {
    Name        = "${local.tenant_name}-db-mcp-protocol-rule"
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
    Service     = "db-mcp-server"
  }
}

# Listener Rule for /sse endpoints to route to db-mcp-server
resource "aws_lb_listener_rule" "db_mcp_sse" {
  listener_arn = module.alb.http_alb_listener_arn
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db_mcp.arn
  }

  condition {
    path_pattern {
      values = ["/sse", "/sse/*"]
    }
  }

  tags = {
    Name        = "${local.tenant_name}-db-mcp-sse-rule"
    Environment = "${local.environment}"
    Tenant      = "${local.tenant_name}"
    Service     = "db-mcp-server"
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
  
  # Enable NAT Gateway for private subnet connectivity
  enabled_nat_gateway        = true
  enabled_single_nat_gateway = true  # Use single NAT gateway to save costs
  
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

  name                   = "${local.tenant_name}-memorydb"
  description            = "MemoryDB cluster for AI Tutor Backend"
  node_type              = "db.t4g.small"
  port                   = 6379
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_ids     = [aws_security_group.memorydb_sg[0].id]
  engine_version         = "7.0"
  num_shards             = 1
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

  # Allow access from ECS tasks security group
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.ecs_fargate.security_group_id]
    description     = "Allow Redis access from ECS tasks"
  }

  # Fallback rule - allow access from VPC CIDR
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [local.cidr_block]
    description = "Allow Redis access from VPC CIDR"
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

# Additional security group rule to allow ECS tasks to connect to MemoryDB
resource "aws_security_group_rule" "ecs_to_memorydb" {
  count                    = local.enable_redis ? 1 : 0
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.memorydb_sg[0].id
  security_group_id        = module.ecs_fargate.security_group_id
  description              = "Allow ECS tasks to connect to MemoryDB"
}

# Bastion host removed - no RDS to access

# API Gateway module disabled - routing directly to ALB
# module "api_gateway" {
#   source = "../modules/api_gateway"
#
#   name        = "${local.tenant_name}-api-gateway"
#   environment = local.environment
#   tenant_name = local.tenant_name
#
#   alb_dns_name = module.alb.alb_dns_name
#   alb_zone_id  = module.alb.alb_zone_id
#
#   # VPC configuration for Lambda function
#   vpc_id             = module.vpc.vpc_id
#   subnet_ids         = module.vpc.private_subnet_ids
#   security_group_ids = [module.alb.security_group_id]
#
#   stage_name     = "prod"
#   enable_cors    = true
#   enable_api_key = false
#
#   throttle_rate_limit  = 1000
#   throttle_burst_limit = 2000
#
#   depends_on = [module.alb, module.ecs_fargate, module.vpc]
# }

# S3 bucket for Terraform state is managed by backend configuration in backend.tf

module "s3-bucket" {
  source      = "../modules/s3"
  bucket_name = "${local.tenant_name}-admin-portal-${data.aws_caller_identity.current.account_id}"
  tags = {
    Environment = "${local.environment}"
    tenant      = "${local.tenant_name}"
  }
}

# Use existing ECR repository instead of creating a new one
data "aws_ecr_repository" "existing" {
  name = "ai-tutor-api"
}

# Note: Using image tags instead of digests for better compatibility
# The force_new_deployment setting will ensure new images are pulled

# Use existing ECR repository for db-mcp-server
data "aws_ecr_repository" "db_mcp_server" {
  name = "db-mcp-server"
}
# Backend configuration removed - using local state for dev





