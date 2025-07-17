variable "region" {
  type        = string
  default     = "ap-northeast-2"
}

variable "api_name" {
  type        = string
  default     = "presign-api"
}

variable "lambda_presign_function_name" {
  type        = string
}

variable "allowed_origin" {
  description = "CloudFront domain name without protocol (e.g. dxxxx.cloudfront.net)"
  type        = string
}


variable "s3_bucket_name" {
  description = "React 프론트엔드 및 alb-config.json이 저장될 S3 버킷 이름"
  type        = string
}
