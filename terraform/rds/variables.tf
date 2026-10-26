variable "rds_security_group_id" {
  description = "security group id for rds function"
  type        = string
}


variable "subnet_ids" {
  description = "subnets rds will be deployed in (minimum 2)"
  type        = list(string)
}

variable "instance_class" {
  description = "rds instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "name of rds db instance"
  type        = string
  default     = "groundwork_rds"
}

variable "engine_version" {
  description = "postgres engine version"
  type        = string
  default     = "18.3"
}

variable "allocated_storage" {
  description = "how much storage to allocate to db in GB"
  type        = number
  default     = 20
}
