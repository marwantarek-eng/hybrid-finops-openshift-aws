output "rds_endpoint" {
   value = aws_db_instance.postgres.endpoint
  description = "The endpoint of the RDS instance"
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "The ARN of the Secrets Manager secret"
}

output "secret_name" {
  value       = aws_secretsmanager_secret.db_password.name
  description = "The name of the Secrets Manager secret"
}
