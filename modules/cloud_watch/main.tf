
resource "aws_cloudwatch_log_group" "ecs-log-group" {
  name = "${var.name}-log-group"
  tags = var.tags
}