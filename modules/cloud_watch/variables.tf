variable "name" {
  type        = string
  description = "The name log group name"
}

variable "tags" {
  description = "A map of tags to add to the resources"
  type        = map(string)
  default     = {}
}