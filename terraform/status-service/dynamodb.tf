resource "aws_dynamodb_table" "statuses_table" {
  name           = "statuses-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "task_id"

  attribute {
    name = "task_id"
    type = "S"
  }
  
  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }
}