resource "aws_secretsmanager_secret" "kafka_auth" {
  name        = var.kafka_secret_name
  description = "Administrative credentials for the Kafka cluster"
  tags = {
    Name = var.kafka_secret_name
  }
}

resource "aws_secretsmanager_secret_version" "kafka_auth_v1" {
  secret_id = aws_secretsmanager_secret.kafka_auth.id
  secret_string = jsonencode({
    username = "admin"
    password = "very-secret-password-123"
  })
}

output "secret_arn" {
  value = aws_secretsmanager_secret.kafka_auth.arn
}
