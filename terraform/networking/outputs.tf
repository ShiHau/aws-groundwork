output "rds_security_group_id" {
  value = aws_security_group.rds_security_group.id
}

output "lambda_app_security_group_id" {
  value = aws_security_group.lambda_app_security_group.id
}

output "bootstrap_security_group_id" {
  value = aws_security_group.bootstrap_security_group.id
}

output "secretsmanager_endpoint_security_group_id" {
  value = aws_security_group.secretsmanager_endpoint_security_group.id
}

output "lambda_reader_security_group_id" {
  value = aws_security_group.lambda_reader_security_group.id
}
