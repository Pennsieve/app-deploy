output "aws_bucket_name" {
  description = "State Bucket Name"

  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "State Table Name"

  value = aws_dynamodb_table.terraform_state_lock.name
}