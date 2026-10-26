resource "aws_security_group" "rds_security_group" {
    vpc_id = var.vpc_id
    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        security_groups = [var.lambda_security_group_id]
    }
    
    tags = {
        Name = "groundwork-rds-security-group"
        Project = "groundwork"
    }

}

resource "aws_db_subnet_group" "rds_subnet" {
  name = "rds_subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "groundwork-rds-subnet-group"
    Project = "groundwork"
  }
}

resource "aws_db_instance" "rds_instance" {
    identifier = "groundwork-rds-db"
    allocated_storage    = var.allocated_storage
    db_name              = var.db_name
    engine               = "postgres"
    engine_version       = var.engine_version
    instance_class       = var.instance_class
    db_subnet_group_name = aws_db_subnet_group.rds_subnet.name
    vpc_security_group_ids = [aws_security_group.rds_security_group.id]
    iam_database_authentication_enabled = true
    skip_final_snapshot  = true

    tags = {
    Name = "groundwork-rds-db"
    Project = "groundwork"
  }
}