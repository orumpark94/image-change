variable "bucket_domain_name" {
  type        = string
  description = "S3 버킷의 도메인 이름 (ex: my-bucket.s3.amazonaws.com)"
}

variable "s3_bucket_name" {
  description = "연결할 S3 버킷 이름"
  type        = string
}

variable "region" {
  type        = string
  default     = "ap-northeast-2"
}