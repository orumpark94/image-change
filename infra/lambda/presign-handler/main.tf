data "archive_file" "presign_handler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/presign-handler"
  output_path = "${path.module}/../../../lambda/presign-handler.zip"
}

resource "aws_iam_role" "presign_lambda_role" {
  name = "${var.lambda_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Role 정의 이후 아래처럼 추가
resource "aws_iam_policy" "allow_kms_lambda" {
  name = "${var.lambda_name}-kms-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy_attachment" "attach_kms_policy" {
  name       = "${var.lambda_name}-kms-policy-attach"
  roles      = [aws_iam_role.presign_lambda_role.name]
  policy_arn = aws_iam_policy.allow_kms_lambda.arn
}

resource "aws_iam_policy_attachment" "presign_lambda_policy" {
  name       = "${var.lambda_name}-policy-attach"
  roles      = [aws_iam_role.presign_lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_lambda_function" "presign_handler" {
  function_name = var.lambda_name

  filename         = data.archive_file.presign_handler_zip.output_path
  source_code_hash = data.archive_file.presign_handler_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs20.x"
  timeout = 5
  role    = aws_iam_role.presign_lambda_role.arn

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
      ALLOWED_ORIGIN = var.allowed_origin
    }
  }
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
