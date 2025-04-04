resource "aws_secretsmanager_secret" "team_secret" {
  name = var.name
}
