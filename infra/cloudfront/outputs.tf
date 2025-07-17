output "cloudfront_domain_name" {
  description = "배포된 CloudFront의 도메인 이름 (예: dxxxxx.cloudfront.net)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront 배포 ID (예: E123456ABC)"
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront 배포의 ARN"
  value       = aws_cloudfront_distribution.this.arn
}

output "origin_access_identity" {
  description = "CloudFront에서 생성한 Origin Access Identity (Canonical User ID)"
  value       = aws_cloudfront_origin_access_identity.this.s3_canonical_user_id
}
