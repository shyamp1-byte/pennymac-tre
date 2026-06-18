output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

# invoke_arn is used when wiring Lambda to API Gateway or EventBridge
output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

# Expose role so callers can attach additional policies (e.g. DynamoDB access)
output "role_arn" {
  description = "ARN of the Lambda IAM execution role"
  value       = aws_iam_role.lambda_exec.arn
}

output "role_name" {
  description = "Name of the Lambda IAM execution role"
  value       = aws_iam_role.lambda_exec.name
}
