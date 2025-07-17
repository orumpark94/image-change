data "archive_file" "resize_handler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/resize-handler"
  output_path = "${path.module}/../../../lambda/resize-handler.zip"
}

resource "aws_iam_role" "resize_lambda_role" {
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

resource "aws_iam_policy_attachment" "resize_lambda_policy" {
  name       = "${var.lambda_name}-policy-attach"
  roles      = [aws_iam_role.resize_lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_lambda_function" "resize_handler" {
  function_name = var.lambda_name

  filename         = data.archive_file.resize_handler_zip.output_path
  source_code_hash = data.archive_file.resize_handler_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs20.x"
  timeout = 5
  role    = aws_iam_role.resize_lambda_role.arn

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
    }
  }
}

# ✅ S3에서 Lambda 호출 허용
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resize_handler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.s3_bucket_name}"
}

# ✅ S3 → Lambda 트리거 구성
resource "aws_s3_bucket_notification" "trigger_lambda" {
  bucket = var.s3_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.resize_handler.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
