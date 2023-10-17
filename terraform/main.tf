provider "aws" {}

// Creates s3 bucket
resource "random_pet" "lambda_bucket_name" {
  prefix = "lambda-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

// Application Gateway Lambda
// creates an archive and uploads to s3 bucket
data "archive_file" "application_gateway_lambda" {
  type = "zip"

  source_dir  = "${path.module}/application-gateway-lambda"
  output_path = "${path.module}/application-gateway-lambda.zip"
}

// provides an s3 object resource
resource "aws_s3_object" "application_gateway_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "application-gateway-lambda.zip"
  source = data.archive_file.application_gateway_lambda.output_path

  etag = filemd5(data.archive_file.application_gateway_lambda.output_path)
}
