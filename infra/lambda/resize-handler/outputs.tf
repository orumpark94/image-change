
output "lambda_function_name" {
  description = "The name of the resize-handler Lambda function"
  value       = aws_lambda_function.resize_handler.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the resize-handler Lambda function"
  value       = aws_lambda_function.resize_handler.arn
}
