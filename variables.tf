
variable "s3_bucket_name" {
  description = "전역 S3 버킷 이름"
  type        = string
  default     = "image-resolution-output-bucket"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"  # 또는 원하는 리전
}
