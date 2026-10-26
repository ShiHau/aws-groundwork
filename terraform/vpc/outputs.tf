output "vpc_id" {
    description = "vpc id"
    value = aws_vpc.groundwork_vpc.id
}

output "private_subnets_ids" {
    description = "if of private subnets in vpc"
    value = [for subnet in aws_subnet.private_subnets: subnet.id]
}