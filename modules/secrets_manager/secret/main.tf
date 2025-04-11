resource "aws_secretsmanager_secret" "team_secret" {
  name       = var.name
  kms_key_id = try(var.kms_key_id, null)
}

resource "aws_secretsmanager_secret_version" "team_secret" {
  secret_id     = aws_secretsmanager_secret.team_secret.id
  secret_string = jsonencode(var.secret_data)
}
