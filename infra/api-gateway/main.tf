data "aws_caller_identity" "current" {}

############################
# REST API
############################
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "API Gateway for image presigned upload URL"
}

############################
# /presign 리소스
############################
resource "aws_api_gateway_resource" "presign" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "presign"
}

############################
# GET /presign
############################
resource "aws_api_gateway_method" "get_presign" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.presign.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_presign" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.presign.id
  http_method             = aws_api_gateway_method.get_presign.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.lambda_presign_function_name}/invocations"
}

############################
# POST /presign
############################
resource "aws_api_gateway_method" "post_presign" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.presign.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_lambda_presign" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.presign.id
  http_method             = aws_api_gateway_method.post_presign.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.lambda_presign_function_name}/invocations"
}

############################
# Lambda Permission
############################
resource "aws_lambda_permission" "api_gw_invoke_presign_post" {
  statement_id  = "AllowAPIGatewayInvokePresignPost"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_presign_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/POST/presign"

  depends_on = [
    aws_api_gateway_method.post_presign,
    aws_api_gateway_integration.post_lambda_presign,
    aws_api_gateway_deployment.this,
    aws_api_gateway_stage.this
  ]
}

############################
# CORS 설정 (GET)
############################
resource "aws_api_gateway_method_response" "get_cors" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.presign.id
  http_method = aws_api_gateway_method.get_presign.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "get_cors" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.presign.id
  http_method = aws_api_gateway_method.get_presign.http_method
  status_code = aws_api_gateway_method_response.get_cors.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.allowed_origin}'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
  }
}

############################
# CORS 설정 (POST)
############################
resource "aws_api_gateway_method_response" "post_cors" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.presign.id
  http_method = aws_api_gateway_method.post_presign.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "post_cors" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.presign.id
  http_method = aws_api_gateway_method.post_presign.http_method
  status_code = aws_api_gateway_method_response.post_cors.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.allowed_origin}'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
  }
}

############################
# OPTIONS /presign (Preflight)
############################
resource "aws_api_gateway_method" "options_presign" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.presign.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_mock" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.presign.id
  http_method             = aws_api_gateway_method.options_presign.http_method
  type                    = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.presign.id
  http_method = aws_api_gateway_method.options_presign.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.presign.id
  http_method = aws_api_gateway_method.options_presign.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${var.allowed_origin}'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
  }

  depends_on = [
    aws_api_gateway_integration.options_mock,
    aws_api_gateway_method_response.options_response
  ]
}

############################
# Deployment
############################
resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_integration.lambda_presign,
    aws_api_gateway_integration_response.get_cors,
    aws_api_gateway_integration_response.post_cors,
    aws_api_gateway_integration_response.options_response
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_stage" "this" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
}

############################
# API Gateway URL → alb-config.json → S3 저장
############################
locals {
  api_gateway_url = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com/${var.stage_name}"
}

data "template_file" "alb_config" {
  template = jsonencode({
    apiUrl = local.api_gateway_url
  })
}

resource "aws_s3_object" "alb_config" {
  bucket       = var.s3_bucket_name
  key          = "alb-config.json"
  content      = data.template_file.alb_config.rendered
  content_type = "application/json"
  depends_on   = [aws_api_gateway_deployment.this]
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
