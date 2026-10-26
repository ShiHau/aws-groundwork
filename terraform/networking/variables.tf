variable "vpc_id" {
  description = "id of the vpc rds will be deployed in"
  type        = string
}

variable "subnet_ids" {
  description = "private subnets the secrets manager endpoint is placed in"
  type        = list(string)
}

variable "region" {
  description = "aws region, used to build the secrets manager endpoint service name"
  type        = string
}
