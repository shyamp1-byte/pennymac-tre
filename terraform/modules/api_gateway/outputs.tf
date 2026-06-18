output "api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.this.id
}

# Full URL the frontend uses to call GET /movers
output "invoke_url" {
  description = "Base invoke URL for the deployed API stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "stage_name" {
  description = "Deployed stage name"
  value       = aws_api_gateway_stage.this.stage_name
}
