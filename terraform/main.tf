provider "aws" {
  region = var.region
}

module "groundwork_vpc" {
  source = "./vpc"

  vpc_cidr_block = "10.0.0.0/16"
  subnets = {
    "groundwork-private-subnet-1" = { cidr_block = "10.0.1.0/24" }
    "groundwork-private-subnet-2" = { cidr_block = "10.0.2.0/24" }
  }
}

module "groundwork_networking" {
  source = "./networking"

  vpc_id     = module.groundwork_vpc.vpc_id
  subnet_ids = module.groundwork_vpc.private_subnet_ids
  region     = var.region
}

module "groundwork_rds" {
  source = "./rds"

  rds_security_group_id = module.groundwork_networking.rds_security_group_id
  subnet_ids            = module.groundwork_vpc.private_subnet_ids
  instance_class        = "db.t4g.micro"
  db_name               = var.db_name
  engine_version        = "18.3"
  allocated_storage     = 20
}

# Creates the database users and the tickets table. Runs as the RDS master user.
module "groundwork_bootstrap" {
  source = "./bootstrap_lambda_rds"

  source_dir                  = abspath("${path.root}/../build/bootstrap")
  subnet_ids                  = module.groundwork_vpc.private_subnet_ids
  bootstrap_security_group_id = module.groundwork_networking.bootstrap_security_group_id
  rds_endpoint                = module.groundwork_rds.rds_endpoint
  db_name                     = var.db_name
  master_username             = module.groundwork_rds.master_username
  master_secret_arn           = module.groundwork_rds.master_secret_arn

  # The secrets manager endpoint must exist before the bootstrap runs.
  depends_on = [module.groundwork_networking]
}

# Writer: can only INSERT into tickets (as lambda_user).
module "groundwork_lambda" {
  source = "./db_lambda"

  # lambda_user and the tickets table must exist first.
  depends_on = [module.groundwork_bootstrap]

  region            = var.region
  lambda_name       = "groundwork_lambda_worker"
  source_dir        = abspath("${path.root}/../build/app_lambda")
  handler           = "main.lambda_handler"
  subnet_ids        = module.groundwork_vpc.private_subnet_ids
  security_group_id = module.groundwork_networking.lambda_app_security_group_id
  db_name           = var.db_name
  db_user           = "lambda_user"
  rds_endpoint      = module.groundwork_rds.rds_endpoint
  db_resource_id    = module.groundwork_rds.db_resource_id
}

# Reader: can only SELECT from tickets (as reader_user).
module "groundwork_reader" {
  source = "./db_lambda"

  # reader_user must exist first.
  depends_on = [module.groundwork_bootstrap]

  region            = var.region
  lambda_name       = "groundwork_lambda_reader"
  source_dir        = abspath("${path.root}/../build/reader")
  handler           = "handler.lambda_handler"
  subnet_ids        = module.groundwork_vpc.private_subnet_ids
  security_group_id = module.groundwork_networking.lambda_reader_security_group_id
  db_name           = var.db_name
  db_user           = "reader_user"
  rds_endpoint      = module.groundwork_rds.rds_endpoint
  db_resource_id    = module.groundwork_rds.db_resource_id
}
