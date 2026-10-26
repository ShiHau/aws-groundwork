variable "vpc_id" {
    description = "id of the vpc rds will be deployed in"
    type = string
}

variable "subnet_ids" {
    description = "subnets rds will be deployed in (minimum 2)"
    type = list(string)
}

variable "instance_class" {
    description = "rds instance class"
    type = string
    default = "db.t3.micro"
}

variable "lambda_security_group_id" {
    description = "lambda security group for rds to accept inbound traffic from"
    type = string
}

variable "db_name" {
    description = "name of rds db instance"
    type = string
    default = "groundwork_rds"
}

variable "engine_version" {
  description = "postgres engine version"
  type        = string
  default     = "15.4"
}

variable "allocated_storage" {
  description = "how much storage to allocate to db in GB"
  type        = number
  default     = 20
}