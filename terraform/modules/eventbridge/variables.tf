variable "rule_name" {
  description = "Name of the EventBridge cron rule"
  type        = string
}

# Cron runs at 12:00 PM UTC (8:00 AM EDT) — fetches previous day's data after Massive has processed it overnight
# AWS cron format: cron(minutes hours day-of-month month day-of-week year)
variable "schedule_expression" {
  description = "EventBridge schedule expression (cron or rate)"
  type        = string
  default     = "cron(0 12 * * ? *)"
}

# ARN of the Lambda function this rule will invoke
variable "lambda_arn" {
  description = "ARN of the target Lambda function"
  type        = string
}

# Function name (not ARN) is required by aws_lambda_permission
variable "lambda_function_name" {
  description = "Name of the target Lambda function"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the EventBridge rule"
  type        = map(string)
  default     = {}
}
