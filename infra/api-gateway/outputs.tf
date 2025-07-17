output "api_invoke_url" {
  description = "API Gateway invoke URL"
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com/prod/presign"
}
