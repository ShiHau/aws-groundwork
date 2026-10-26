variable "region" {
  description = "aws region"
  type        = string
  default     = "ap-southeast-1"
}

variable "lambda_security_group_id" {
  description = "security group id for lambda function"
  type        = string
}

variable "subnet_ids" {
  description = "subnets rds will be deployed in (minimum 2)"
  type        = list(string)
}

variable "lambda_name" {
  description = "name of lambda function"
  type        = string
  default     = "groundwork_lambda_app"
}

variable "source_dir" {
  description = "path to lambda function with additional build dependencies"
  type        = string
}

variable "handler" {
  description = "name of function inside python file that lambda executes"
  type        = string
}

variable "runtime" {
  description = "runtime version to use"
  type        = string
  default     = "python3.12"
}

variable "db_name" {
  description = "rds db name to connect to"
  type        = string
  default     = "groundwork_rds"
}

variable "rds_endpoint" {
  description = "rds database endpoint to send request to"
  type        = string
}

variable "db_resource_id" {
  description = "RDS DbiResourceId, used to scope rds-db:connect"
  type        = string
}

variable "db_user" {
  description = "database user the lambda authenticates as via IAM"
  type        = string
  default     = "lambda_user"
}

variable "rds_security_group_id" {
  description = "security group for rds for lambda to connect to"
  type        = string
}
