# Cron rule — fires on schedule_expression, disabled state means it won't run until enabled
resource "aws_cloudwatch_event_rule" "cron" {
  name                = var.rule_name
  schedule_expression = var.schedule_expression
  state               = "ENABLED"
  tags                = var.tags
}

# Wires the cron rule to the ingestion Lambda as its target
resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.cron.name
  arn  = var.lambda_arn
}

# Grants EventBridge permission to invoke the Lambda — without this, the trigger is silently ignored
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron.arn
}
