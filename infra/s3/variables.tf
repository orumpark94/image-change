variable "s3_bucket_name" {
  description = "이미지 해상도 출력용 S3 버킷 이름"
  type        = string
  default     = "image-resolution-output-bucket"
}

variable "resized_image_expire_days" {
  description = "리사이징된 이미지가 만료되기까지의 일 수"
  type        = number
  default     = 30
}


variable "cloudfront_domain_name" {
  description = "CloudFront 도메인 이름 (CORS 설정용)"
  type        = string
}

variable "origin_access_identity" {
  description = "CloudFront OAI의 CanonicalUser ID"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront 배포의 ARN"
  type        = string
}

#variable "resize_lambda_name" {
#  description = "리사이징용 Lambda 함수 이름"
#  type        = string
#}

#variable "resize_lambda_arn" {
#  description = "리사이징용 Lambda ARN"
#  type        = string
#}
