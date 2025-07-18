

# S3 버킷 생성
resource "aws_s3_bucket" "output_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "image-resolution-output"
    Environment = "dev"
  }
}

# 퍼블릭 접근 완전 차단
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.output_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# 서버사이드 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.output_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# CORS 설정 - CloudFront 도메인만 허용
resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.output_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://${var.cloudfront_domain_name}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}


# Lifecycle Rule - /resized/ 경로 파일 자동 만료
resource "aws_s3_bucket_lifecycle_configuration" "expire_old_resized" {
  bucket = aws_s3_bucket.output_bucket.id

  rule {
    id     = "ExpireOldResizedImages"
    status = "Enabled"

    filter {
      prefix = "resized/"
    }

    expiration {
      days = var.resized_image_expire_days
    }
  }
}

# ✅ CloudFront OAI(CanonicalUser ID) 기반 버킷 정책
resource "aws_s3_bucket_policy" "allow_cf_read" {
  bucket = aws_s3_bucket.output_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowCloudFrontReadOnly",
        Effect = "Allow",
        Principal = {
          "CanonicalUser": var.origin_access_identity
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.output_bucket.arn}/*"
      }
    ]
  })
}

#resource "aws_lambda_permission" "allow_s3_to_invoke_resize" {
#  statement_id  = "AllowS3InvokeResizeLambda"
#  action        = "lambda:InvokeFunction"
#  function_name = var.resize_lambda_name
#  principal     = "s3.amazonaws.com"
#  source_arn    = aws_s3_bucket.output_bucket.arn
#}

#resource "aws_s3_bucket_notification" "s3_to_resize_lambda" {
#  bucket = aws_s3_bucket.output_bucket.id

#  lambda_function {
#    lambda_function_arn = var.resize_lambda_arn
#    events              = ["s3:ObjectCreated:*"]
#    filter_prefix       = "uploads/"   # 사용자가 업로드할 디렉토리
#    filter_suffix       = ".jpg"       # 확장자 (필요 시 여러 번 정의 가능)
#  }

#  depends_on = [aws_lambda_permission.allow_s3_to_invoke_resize]
#}


terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
