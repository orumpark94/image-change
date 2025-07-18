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
