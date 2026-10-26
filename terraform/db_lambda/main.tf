data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Allows IAM database login as exactly one database user on exactly one instance.
data "aws_iam_policy_document" "rds_connect" {
  statement {
    effect    = "Allow"
    actions   = ["rds-db:connect"]
    resources = ["arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.db_resource_id}/${var.db_user}"]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.lambda_name}_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "rds_connect" {
  name   = "rds-db-iam-auth"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.rds_connect.json
}

resource "aws_iam_role_policy_attachment" "vpc_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "archive_file" "code" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/${var.lambda_name}.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = var.lambda_name
  filename         = data.archive_file.code.output_path
  role             = aws_iam_role.this.arn
  handler          = var.handler
  source_code_hash = data.archive_file.code.output_base64sha256

  runtime     = var.runtime
  timeout     = var.timeout
  memory_size = var.memory_size

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  environment {
    variables = {
      db_name     = var.db_name
      db_endpoint = var.rds_endpoint
    }
  }

  tags = {
    Name    = var.lambda_name
    Project = "groundwork"
  }
}
