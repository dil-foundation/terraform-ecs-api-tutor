# Terraform module which creates ECS Fargate resources on AWS.
# ECS Service
# https://www.terraform.io/docs/providers/aws/r/ecs_service.html
resource "aws_ecs_service" "default" {
  count                              = var.enabled ? 1 : 0
  name                               = var.name
  task_definition                    = aws_ecs_task_definition.default[0].arn
  cluster                            = var.cluster
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_controller {
    # The deployment controller type to use. Valid values: CODE_DEPLOY, ECS.
    type = var.deployment_controller_type
  }

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html
  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.default[0].id]

    # Whether the task's elastic network interface receives a public IP address.
    assign_public_ip = var.assign_public_ip
  }

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html#load-balancing-concepts
  load_balancer {
    # The ARN of the Load Balancer target group to associate with the service.
    target_group_arn = var.target_group_arn

    # The name of the container to associate with the load balancer (as it appears in a container definition).
    container_name = var.container_name

    # The port on the container to associate with the load balancer.
    container_port = var.container_port
  }

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-create-loadbalancer-rolling.html
  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html
  platform_version = var.platform_version

  # The launch type on which to run your service.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html
  launch_type = "FARGATE"

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html#service_scheduler_replica
  scheduling_strategy = "REPLICA"

  lifecycle {
    # https://www.terraform.io/docs/providers/aws/r/ecs_service.html#ignoring-changes-to-desired-count
    ignore_changes = [desired_count]
  }
}

# Security Group for ECS Service
#
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "default" {
  count = var.enabled ? 1 : 0

  name   = local.security_group_name
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = local.security_group_name }, var.tags)
}

locals {
  security_group_name = "${var.name}-ecs-fargate"
}

# https://www.terraform.io/docs/providers/aws/r/security_group_rule.html
resource "aws_security_group_rule" "ingress" {
  count = var.enabled ? 1 : 0

  type              = "ingress"
  from_port         = var.container_port
  to_port           = var.container_port
  protocol          = "tcp"
  cidr_blocks       = var.source_cidr_blocks
  security_group_id = aws_security_group.default[0].id
}

resource "aws_security_group_rule" "egress" {
  count = var.enabled ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default[0].id
}

# ECS Task Definitions
#
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html

# https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html
resource "aws_ecs_task_definition" "default" {
  count = var.enabled ? 1 : 0

  # A unique name for your task definition.
  family = var.name

  # The ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume.
  execution_role_arn = var.create_ecs_task_execution_role ? join("", aws_iam_role.default.*.arn) : var.ecs_task_execution_role_arn

  # A list of container definitions in JSON format that describe the different containers that make up your task.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions
  container_definitions = var.container_definitions

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
  cpu = var.cpu

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
  memory = var.memory

  # The launch type that the task is using.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#requires_compatibilities
  requires_compatibilities = var.requires_compatibilities

  # Fargate infrastructure support the awsvpc network mode.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#network_mode
  network_mode = "awsvpc"

  # A mapping of tags to assign to the resource.
  tags = merge({ "Name" = var.name }, var.tags)
}

# ECS Task Execution IAM Role
#
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html

# https://www.terraform.io/docs/providers/aws/r/iam_role.html
resource "aws_iam_role" "default" {
  count = local.enabled_ecs_task_execution

  name               = local.iam_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  path               = var.iam_path
  description        = var.description
  tags               = merge({ "Name" = local.iam_name }, var.tags)
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# https://www.terraform.io/docs/providers/aws/r/iam_policy.html
resource "aws_iam_policy" "default" {
  count = local.enabled_ecs_task_execution

  name        = local.iam_name
  policy      = data.aws_iam_policy.ecs_task_execution.policy
  path        = var.iam_path
  description = var.description
}

# https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
resource "aws_iam_role_policy_attachment" "default" {
  count = local.enabled_ecs_task_execution

  role       = aws_iam_role.default[0].name
  policy_arn = aws_iam_policy.default[0].arn
}

locals {
  iam_name                   = "${var.name}-ecs-task-execution"
  enabled_ecs_task_execution = var.enabled ? 1 : 0 && var.create_ecs_task_execution_role ? 1 : 0
}

data "aws_iam_policy" "ecs_task_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Application Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  count = var.enabled && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster}/${aws_ecs_service.default[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Application Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  count = var.enabled && var.enable_autoscaling ? 1 : 0

  name               = "${var.name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}

# Application Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  count = var.enabled && var.enable_autoscaling ? 1 : 0

  name               = "${var.name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.memory_target_value
  }
}

# CloudWatch Log Group for ECS Service
resource "aws_cloudwatch_log_group" "ecs_service" {
  count = var.enabled && var.enable_autoscaling ? 1 : 0

  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}
