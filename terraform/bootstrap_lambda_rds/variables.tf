variable "lambda_name" {
  description = "name of the bootstrap lambda function"
  type        = string
  default     = "groundwork_rds_bootstrap"
}

variable "source_dir" {
  description = "directory containing the bootstrap handler, its dependencies and the SQL file"
  type        = string
}

variable "handler" {
  description = "handler the bootstrap lambda executes"
  type        = string
  default     = "handler.lambda_handler"
}

variable "runtime" {
  description = "runtime version to use"
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "bootstrap lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "subnet_ids" {
  description = "private subnets the bootstrap lambda runs in"
  type        = list(string)
}

variable "bootstrap_security_group_id" {
  description = "security group for the bootstrap lambda"
  type        = string
}

variable "rds_endpoint" {
  description = "rds hostname (without port)"
  type        = string
}

variable "db_name" {
  description = "database the bootstrap SQL runs against"
  type        = string
}

variable "master_username" {
  description = "rds master username"
  type        = string
}

variable "master_secret_arn" {
  description = "arn of the RDS-managed master user secret"
  type        = string
}
