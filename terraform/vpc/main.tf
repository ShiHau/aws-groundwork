
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "groundwork_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "groundwork-vpc"
    Project = "groundwork"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.groundwork_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = data.aws_availability_zones.available.names[index(keys(var.subnets), each.key)]

  tags = {
    Name    = each.key
    Project = "groundwork"
  }
}
