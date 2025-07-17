variable "lambda_name" {
  description = "Lambda 함수 이름"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 버킷 이름"
  type        = string
}

variable "allowed_origin" {
  description = "CORS 허용 도메인 (CloudFront 주소)"
  type        = string
}
