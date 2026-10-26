variable "region" {
  description = "aws region everything is deployed in"
  type        = string
  default     = "ap-southeast-1"
}

variable "db_name" {
  description = "rds database name; must match the database name in app/bootstrap/rds_bootstrap.sql"
  type        = string
  default     = "groundwork_rds_db"
}
