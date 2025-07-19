output "api_invoke_base_url" {
  description = "API Gateway invoke base URL"
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com/prod"
}
