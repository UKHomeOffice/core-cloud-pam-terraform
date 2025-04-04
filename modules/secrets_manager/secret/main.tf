resource "aws_secretsmanager_secret" "team_secret" {
  name = var.name
  kms_key_id = try(var.kms_key_id, null)
}
