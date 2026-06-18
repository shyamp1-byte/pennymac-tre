# ── DynamoDB ──────────────────────────────────────────────────────────────────

module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = var.table_name
  tags       = var.tags
}

# ── Lambda: Ingestion (EventBridge → writes to DynamoDB) ─────────────────────

module "ingestion_lambda" {
  source        = "./modules/lambda"
  function_name = "stock-mover-ingestion"
  source_dir    = "${path.root}/../lambdas/ingestion"
  timeout       = 30 # 6 sequential API calls need more than the 10s default
  environment_variables = {
    TABLE_NAME    = module.dynamodb.table_name
    STOCK_API_KEY = var.stock_api_key
  }
  tags = var.tags
}

# DynamoDB write-only policy for ingestion — least privilege (no read needed)
resource "aws_iam_role_policy" "ingestion_dynamodb" {
  name = "stock-mover-ingestion-dynamodb-write"
  role = module.ingestion_lambda.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem"]
      Resource = module.dynamodb.table_arn
    }]
  })
}

# ── Lambda: Retrieval (API Gateway → reads from DynamoDB) ────────────────────

module "retrieval_lambda" {
  source        = "./modules/lambda"
  function_name = "stock-mover-retrieval"
  source_dir    = "${path.root}/../lambdas/retrieval"
  environment_variables = {
    TABLE_NAME = module.dynamodb.table_name
  }
  tags = var.tags
}

# DynamoDB read-only policy for retrieval — least privilege (no write needed)
resource "aws_iam_role_policy" "retrieval_dynamodb" {
  name = "stock-mover-retrieval-dynamodb-read"
  role = module.retrieval_lambda.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem"]
      Resource = module.dynamodb.table_arn
    }]
  })
}

# ── EventBridge ───────────────────────────────────────────────────────────────

module "eventbridge" {
  source               = "./modules/eventbridge"
  rule_name            = "stock-mover-daily-cron"
  lambda_arn           = module.ingestion_lambda.function_arn
  lambda_function_name = module.ingestion_lambda.function_name
  tags                 = var.tags
}

# ── API Gateway ───────────────────────────────────────────────────────────────

module "api_gateway" {
  source               = "./modules/api_gateway"
  api_name             = "stock-mover-api"
  lambda_invoke_arn    = module.retrieval_lambda.invoke_arn
  lambda_function_name = module.retrieval_lambda.function_name
  tags                 = var.tags
}

# ── S3 Frontend Hosting ───────────────────────────────────────────────────────

resource "aws_s3_bucket" "frontend" {
  bucket = "stock-mover-frontend-${data.aws_caller_identity.current.account_id}"
  tags   = var.tags
}

# Must disable block-public-access before a public bucket policy can be applied
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

# Allow anyone to read objects — required for public static website hosting
resource "aws_s3_bucket_policy" "frontend_public_read" {
  bucket = aws_s3_bucket.frontend.id

  # depends_on ensures public access block is disabled before applying policy
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

# Used to make the S3 bucket name unique per AWS account
data "aws_caller_identity" "current" {}
