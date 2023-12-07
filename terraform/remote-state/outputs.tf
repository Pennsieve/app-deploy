output "aws_bucket_name" {
  description = "Bucket Name"

  value = aws_s3_bucket.terraform_state.bucket
}