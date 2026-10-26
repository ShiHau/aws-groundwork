output "rds_endpoint" {
  description = "RDS instance hostname (without port)"
  value       = aws_db_instance.rds_instance.address
}

output "db_resource_id" {
  description = "RDS DbiResourceId (used in rds-db:connect ARNs)"
  value       = aws_db_instance.rds_instance.resource_id
}

output "master_secret_arn" {
  description = "ARN of the RDS-managed master user secret"
  value       = aws_db_instance.rds_instance.master_user_secret[0].secret_arn
}

output "master_username" {
  description = "RDS master username"
  value       = aws_db_instance.rds_instance.username
}
