provider "aws" {}

resource "random_uuid" "val" {
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "i3h-dev-app-state-v2"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id

    versioning_configuration {
      status = "Enabled"
    }
}

# trigger lambda from S3
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.application_state.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.terraform_state.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.terraform_state.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.application_state.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}