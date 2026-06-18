# Paste this URL into the frontend's fetch() call
output "api_url" {
  description = "Full URL for the GET /movers endpoint"
  value       = "${module.api_gateway.invoke_url}/movers"
}

# Public URL of the S3-hosted frontend
output "frontend_url" {
  description = "S3 static website URL"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "bucket_name" {
  description = "S3 frontend bucket name (used by CI to upload index.html)"
  value       = aws_s3_bucket.frontend.id
}
