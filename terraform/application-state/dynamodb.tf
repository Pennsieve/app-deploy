resource "aws_dynamodb_table" "applications_table" {
  name           = "applications-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "app_id"

  attribute {
    name = "app_id"
    type = "S"
  }
  
  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }
}