# Override to namespace tables per environment (e.g. "stock-movers-prod")
variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "stock-movers"
}

# PAY_PER_REQUEST is free-tier friendly
variable "billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "tags" {
  description = "Tags to apply to the DynamoDB table"
  type        = map(string)
  default     = {}
}
