// Creates Secrets Manager resource
resource "aws_secretsmanager_secret" "api_key_secret" {
  name = "api-key-secret-${random_uuid.val.id}"
}

resource "aws_secretsmanager_secret_version" "api_key_secret" {
  secret_id     = aws_secretsmanager_secret.api_key_secret.id
  secret_string = jsonencode(var.api_key_secret)
}