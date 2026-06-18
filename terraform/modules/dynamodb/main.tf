# DynamoDB table for daily stock mover records
resource "aws_dynamodb_table" "stock_movers" {
  name         = var.table_name
  billing_mode = var.billing_mode # PAY_PER_REQUEST = no provisioned capacity, billed per read/write
  hash_key     = "date"           # partition key; each item is one day's snapshot

  # Only key attributes need schema definitions — ticker, percent_change, closing_price
  attribute {
    name = "date"
    type = "S"
  }

  tags = var.tags
}
