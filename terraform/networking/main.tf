# ---------------------------------------------------------------------------
# Security groups
# ---------------------------------------------------------------------------

resource "aws_security_group" "rds_security_group" {
  vpc_id = var.vpc_id
  tags = {
    Name    = "groundwork-rds-security-group"
    Project = "groundwork"
  }
}

resource "aws_security_group" "lambda_app_security_group" {
  vpc_id = var.vpc_id
  tags = {
    Name    = "groundwork-lambda-app-security-group"
    Project = "groundwork"
  }
}

resource "aws_security_group" "lambda_reader_security_group" {
  vpc_id = var.vpc_id
  tags = {
    Name    = "groundwork-lambda-reader-security-group"
    Project = "groundwork"
  }
}

resource "aws_security_group" "bootstrap_security_group" {
  vpc_id = var.vpc_id
  tags = {
    Name    = "groundwork-bootstrap-security-group"
    Project = "groundwork"
  }
}

resource "aws_security_group" "secretsmanager_endpoint_security_group" {
  vpc_id = var.vpc_id
  tags = {
    Name    = "groundwork-secretsmanager-endpoint-security-group"
    Project = "groundwork"
  }
}

# ---------------------------------------------------------------------------
# App (writer) lambda <-> RDS
# ---------------------------------------------------------------------------

resource "aws_security_group_rule" "lambda_egress_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_app_security_group.id
  source_security_group_id = aws_security_group.rds_security_group.id
}

resource "aws_security_group_rule" "rds_ingress_from_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_security_group.id
  source_security_group_id = aws_security_group.lambda_app_security_group.id
}

# ---------------------------------------------------------------------------
# Reader lambda <-> RDS
# ---------------------------------------------------------------------------

resource "aws_security_group_rule" "reader_egress_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_reader_security_group.id
  source_security_group_id = aws_security_group.rds_security_group.id
}

resource "aws_security_group_rule" "rds_ingress_from_reader" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_security_group.id
  source_security_group_id = aws_security_group.lambda_reader_security_group.id
}

# ---------------------------------------------------------------------------
# Bootstrap lambda <-> RDS
# ---------------------------------------------------------------------------

resource "aws_security_group_rule" "bootstrap_egress_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bootstrap_security_group.id
  source_security_group_id = aws_security_group.rds_security_group.id
}

resource "aws_security_group_rule" "rds_ingress_from_bootstrap" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_security_group.id
  source_security_group_id = aws_security_group.bootstrap_security_group.id
}

# ---------------------------------------------------------------------------
# Bootstrap lambda <-> Secrets Manager (fetches the master password)
# ---------------------------------------------------------------------------

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_ids[0]]
  security_group_ids  = [aws_security_group.secretsmanager_endpoint_security_group.id]
  private_dns_enabled = true

  tags = {
    Name    = "groundwork-secretsmanager-endpoint"
    Project = "groundwork"
  }
}

resource "aws_security_group_rule" "bootstrap_egress_to_endpoint" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bootstrap_security_group.id
  source_security_group_id = aws_security_group.secretsmanager_endpoint_security_group.id
}

resource "aws_security_group_rule" "endpoint_ingress_from_bootstrap" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.secretsmanager_endpoint_security_group.id
  source_security_group_id = aws_security_group.bootstrap_security_group.id
}
