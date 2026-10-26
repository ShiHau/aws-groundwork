output "rds_security_group_id" {
    description = "rds security group"
    value = aws_security_group.rds_security_group.id
}

output "rds_endpoint" {
  description = "rds instance endpoint"
  value = aws_db_instance.rds_instance.endpoint
}