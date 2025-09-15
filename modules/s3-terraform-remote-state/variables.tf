variable "bucket_name" {
  description = "Name of the s3 bucket. Must be unique."
  type = string
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "A mapping of tags to assign to all resources."
}