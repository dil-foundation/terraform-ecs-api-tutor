resource "aws_memorydb_subnet_group" "memorydb_subnet_group" {
  count      = var.enabled ? 1 : 0
  name       = "${var.name}-memorydb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_memorydb_parameter_group" "memorydb_parameter_group" {
  count  = var.enabled ? 1 : 0
  family = var.parameter_group_family
  name   = "${var.name}-memorydb-params"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = var.tags
}

resource "aws_memorydb_cluster" "memorydb" {
  count = var.enabled ? 1 : 0

  name                       = var.name
  acl_name                   = aws_memorydb_acl.memorydb_acl[0].name
  description                = var.description
  node_type                  = var.node_type
  port                       = var.port
  parameter_group_name       = aws_memorydb_parameter_group.memorydb_parameter_group[0].name
  subnet_group_name          = aws_memorydb_subnet_group.memorydb_subnet_group[0].name
  security_group_ids         = var.security_group_ids
  num_shards                 = var.num_shards
  num_replicas_per_shard     = var.num_replicas_per_shard
  engine_version             = var.engine_version
  maintenance_window         = var.maintenance_window
  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window            = var.snapshot_window
  snapshot_name              = var.snapshot_name
  final_snapshot_name        = var.final_snapshot_name
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  kms_key_arn                = var.kms_key_arn
  tls_enabled                = var.tls_enabled

  tags = var.tags
}

resource "aws_memorydb_user" "memorydb_user" {
  count         = var.enabled ? 1 : 0
  user_name     = "default-user"
  access_string = "on ~* &* +@all"

  authentication_mode {
    type = "iam"
  }

  tags = var.tags
}

resource "aws_memorydb_acl" "memorydb_acl" {
  count      = var.enabled ? 1 : 0
  name       = "${var.name}-acl"
  user_names = [aws_memorydb_user.memorydb_user[0].user_name]

  tags = var.tags
}
