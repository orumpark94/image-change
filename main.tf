provider "aws" {
  region = var.region
}

module "cloudfront" {
  source            = "./infra/cloudfront"
  s3_bucket_name    = var.s3_bucket_name                            
  bucket_domain_name = "${var.s3_bucket_name}.s3.amazonaws.com"     
  providers = {
    aws = aws
  }

}


module "s3" {
  source = "./infra/s3"
  s3_bucket_name = var.s3_bucket_name
  cloudfront_domain_name = module.cloudfront.cloudfront_domain_name
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn
  origin_access_identity = module.cloudfront.origin_access_identity
  resized_image_expire_days = 30

  #resize_lambda_name = module.lambda_resize.lambda_function_name
  #resize_lambda_arn  = module.lambda_resize.lambda_function_arn
  providers = {
    aws = aws
  }
  depends_on = [module.cloudfront]
}

module "lambda_presign" {
  source = "./infra/lambda/presign-handler"
  lambda_name = "presign-handler"
  s3_bucket_name = module.s3.bucket_name
  allowed_origin = "https://${module.cloudfront.cloudfront_domain_name}"
  providers = {
    aws = aws
  }
  depends_on = [module.s3, module.cloudfront]
}

module "lambda_resize" {
  source = "./infra/lambda/resize-handler"
  lambda_name = "resize-handler"
  s3_bucket_name = module.s3.bucket_name
  providers = {
    aws = aws
  }
  depends_on = [module.s3, module.cloudfront]
}

module "api_gateway" {
  source = "./infra/api-gateway"
  region = var.region
  api_name = "presign-api"
  lambda_presign_function_name = module.lambda_presign.lambda_function_name
  allowed_origin = module.cloudfront.cloudfront_domain_name
  s3_bucket_name = module.s3.bucket_name
  providers = {
    aws = aws
  }
  depends_on = [module.lambda_presign, module.cloudfront]
}


terraform {
  backend "s3" {
    bucket = "image-resolution-tfstate-bucket"     # 위에서 만든 버킷 이름과 일치
    key    = "state/infra.tfstate"                 # 원하는 경로 (예: per env)
    region = "ap-northeast-2"
    encrypt = true
  }
  
}
