variable "api_name" {
  description = "Name of the API Gateway REST API"
  type        = string
}

# invoke_arn (not function ARN) is required for the Lambda proxy integration URI
variable "lambda_invoke_arn" {
  description = "Invoke ARN of the retrieval Lambda function"
  type        = string
}

# Function name (not ARN) required by aws_lambda_permission
variable "lambda_function_name" {
  description = "Name of the retrieval Lambda function"
  type        = string
}

variable "stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tags to apply to the REST API"
  type        = map(string)
  default     = {}
}
