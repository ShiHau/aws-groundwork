

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds_subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name    = "groundwork-rds-subnet-group"
    Project = "groundwork"
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier                          = "groundwork-rds-db"
  allocated_storage                   = var.allocated_storage
  db_name                             = var.db_name
  engine                              = "postgres"
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  db_subnet_group_name                = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids              = [var.rds_security_group_id]
  username                            = "groundwork_admin"
  manage_master_user_password         = true
  iam_database_authentication_enabled = true
  skip_final_snapshot                 = true
  storage_encrypted                   = true

  tags = {
    Name    = "groundwork-rds-db"
    Project = "groundwork"
  }
}
