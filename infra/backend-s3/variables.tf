variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "bucket_name" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "image-resolution-tfstate-bucket"  # 원하는 이름으로 변경 가능
}
