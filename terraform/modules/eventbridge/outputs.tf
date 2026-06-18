# Useful for debugging in CloudWatch or referencing in other modules
output "rule_arn" {
  description = "ARN of the EventBridge cron rule"
  value       = aws_cloudwatch_event_rule.cron.arn
}

output "rule_name" {
  description = "Name of the EventBridge cron rule"
  value       = aws_cloudwatch_event_rule.cron.name
}
