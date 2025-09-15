variable "name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tenant_name" {
  description = "Tenant name"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  type        = string
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "enable_cors" {
  description = "Enable CORS for the API"
  type        = bool
  default     = true
}

variable "enable_api_key" {
  description = "Enable API key for the API"
  type        = bool
  default     = false
}

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 1000
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 2000
}

variable "vpc_id" {
  description = "VPC ID for Lambda function"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for Lambda function"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for Lambda function"
  type        = list(string)
}
