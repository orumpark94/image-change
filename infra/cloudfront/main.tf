resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "OAI for CloudFront to access S3 securely"
}

resource "aws_cloudfront_response_headers_policy" "secure_policy" {
  name = "secure-response-policy"

  security_headers_config {
    content_type_options {
      override = true
    }

    content_security_policy {
      override = true
      content_security_policy = <<EOF
default-src 'self';
script-src 'self' 'unsafe-inline';
style-src 'self' 'unsafe-inline';
img-src 'self' data:;
connect-src 'self' https:;
EOF
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = "${var.s3_bucket_name}.s3.${var.region}.amazonaws.com"
    origin_id   = "s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    response_headers_policy_id = aws_cloudfront_response_headers_policy.secure_policy.id
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "secure-cloudfront"
  }
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
