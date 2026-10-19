resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "aws_secretsmanager_secret" "db_password" {
  name = "finops-db-credentials"
    description = "Database credentials for FinOps application"
    recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.password.result
    engine   = "postgres"
    port     = 5432
  })
}
