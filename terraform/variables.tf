variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

# Passed via TF_VAR_stock_api_key env var — never hardcoded or committed
variable "stock_api_key" {
  description = "API key for stock data provider (Massive)"
  type        = string
  sensitive   = true
}

variable "table_name" {
  description = "DynamoDB table name for stock movers"
  type        = string
  default     = "stock-movers"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    project = "pennymac-tre"
  }
}
