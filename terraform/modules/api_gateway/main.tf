# REST API — acts as the public-facing entry point
resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name
  tags = var.tags
}

# /movers resource — maps to the GET /movers endpoint
resource "aws_api_gateway_resource" "movers" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "movers"
}

# GET method — no auth required, frontend calls this directly
resource "aws_api_gateway_method" "get_movers" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.movers.id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda proxy integration — passes full request to Lambda, Lambda owns the response shape
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.movers.id
  http_method             = aws_api_gateway_method.get_movers.http_method
  integration_http_method = "POST" # API Gateway always calls Lambda via POST internally
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Deployment is immutable — a new one must be created when the API changes
# depends_on ensures it waits for method + integration to exist before deploying
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.movers.id,
      aws_api_gateway_method.get_movers.id,
      aws_api_gateway_integration.lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage — defines the live URL path (e.g. /prod/movers)
resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name
  tags          = var.tags
}

# Grants API Gateway permission to invoke the Lambda — required or calls return 500
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
