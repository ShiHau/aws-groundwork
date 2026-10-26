variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "full subnet object, can be singular or multiple"
  type = map(object({
    cidr_block = string
  }))
  default = {
    "private-subnet-1" = { cidr_block = "10.0.1.0/24" },
    "private-subnet-2" = { cidr_block = "10.0.2.0/24" }
  }
}