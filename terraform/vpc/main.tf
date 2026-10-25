provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "groundwork_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "groundwork-vpc"
  }
}

resource "aws_subnet" "groundwork_private_subnet" {
  vpc_id            = aws_vpc.groundwork_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "groundwork-private-subnet"
  }
}