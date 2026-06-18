# Expose table name so callers can reference it (e.g. in Lambda env vars)
output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.stock_movers.name
}

# Expose ARN for IAM policy attachments
output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.stock_movers.arn
}
