variable "region" {
  description = "aws region"
  type        = string
}

variable "lambda_name" {
  description = "name of the lambda function"
  type        = string
}

variable "source_dir" {
  description = "directory containing the handler and its dependencies"
  type        = string
}

variable "handler" {
  description = "handler the lambda executes, as file.function"
  type        = string
}

variable "runtime" {
  description = "lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "lambda timeout in seconds"
  type        = number
  default     = 15
}

variable "memory_size" {
  description = "lambda memory in MB"
  type        = number
  default     = 256
}

variable "subnet_ids" {
  description = "private subnets the lambda runs in"
  type        = list(string)
}

variable "security_group_id" {
  description = "security group attached to the lambda"
  type        = string
}

variable "db_name" {
  description = "rds database name to connect to"
  type        = string
}

variable "db_user" {
  description = "database user the lambda authenticates as via IAM"
  type        = string
}

variable "rds_endpoint" {
  description = "rds hostname (without port)"
  type        = string
}

variable "db_resource_id" {
  description = "RDS DbiResourceId, used to scope rds-db:connect"
  type        = string
}
