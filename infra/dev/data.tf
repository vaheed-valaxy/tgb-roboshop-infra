# Read existing AWS Secrets Manager Secret (which is already created)
data "aws_secretsmanager_secret" "roboshop_secret" {
  name = local.aws_secret_name
}

data "aws_secretsmanager_secret_version" "roboshop_secret_value" {
  secret_id = data.aws_secretsmanager_secret.roboshop_secret.id
}
