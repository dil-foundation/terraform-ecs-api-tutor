variable "enabled" {
  description = "Whether to create the MemoryDB cluster"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the MemoryDB cluster"
  type        = string
}

variable "description" {
  description = "Description of the MemoryDB cluster"
  type        = string
  default     = "MemoryDB cluster for AI Tutor Backend"
}

variable "node_type" {
  description = "Instance type for the MemoryDB cluster"
  type        = string
  default     = "db.t4g.small"
}

variable "port" {
  description = "Port number for the MemoryDB cluster"
  type        = number
  default     = 6379
}

variable "subnet_ids" {
  description = "List of subnet IDs for the MemoryDB subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the MemoryDB cluster"
  type        = list(string)
}

variable "parameter_group_family" {
  description = "Parameter group family for MemoryDB"
  type        = string
  default     = "memorydb_redis7"
}

variable "parameters" {
  description = "List of parameters to apply to the parameter group"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "num_shards" {
  description = "Number of shards in the cluster"
  type        = number
  default     = 1
}

variable "num_replicas_per_shard" {
  description = "Number of replicas per shard"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "MemoryDB engine version"
  type        = string
  default     = "7.0"
}

variable "maintenance_window" {
  description = "Maintenance window for the cluster"
  type        = string
  default     = "sun:05:00-sun:09:00"
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 5
}

variable "snapshot_window" {
  description = "Daily time range for snapshots"
  type        = string
  default     = "03:00-05:00"
}

variable "snapshot_name" {
  description = "Name of the snapshot to restore from"
  type        = string
  default     = null
}

variable "final_snapshot_name" {
  description = "Name of the final snapshot"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "tls_enabled" {
  description = "Enable TLS encryption"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the MemoryDB cluster"
  type        = map(string)
  default     = {}
}
