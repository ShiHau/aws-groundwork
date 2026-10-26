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

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "rds_connect" {
  statement {
    effect    = "Allow"
    actions   = ["rds-db:connect"]
    resources = ["arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.db_resource_id}/${var.db_user}"]
  }
}

resource "aws_iam_role" "lambda_app_iam_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "iam_db_auth_rds" {
  name   = "rds-db-iam-auth"
  policy = data.aws_iam_policy_document.rds_connect.json
}

resource "aws_iam_role_policy_attachment" "rds_policy_attachment" {
  role       = aws_iam_role.lambda_app_iam_role.name
  policy_arn = aws_iam_policy.iam_db_auth_rds.arn
}

resource "aws_iam_role_policy_attachment" "vpc_execution" {
  role       = aws_iam_role.lambda_app_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "archive_file" "lambda_app_code" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "lambda_app" {
  function_name    = var.lambda_name
  filename         = data.archive_file.lambda_app_code.output_path
  role             = aws_iam_role.lambda_app_iam_role.arn
  handler          = var.handler
  source_code_hash = data.archive_file.lambda_app_code.output_base64sha256

  runtime     = var.runtime
  timeout     = 15
  memory_size = 256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      db_name     = var.db_name
      db_endpoint = var.rds_endpoint
    }
  }

  tags = {
    Name    = "groundwork-lambda-app-function"
    Project = "groundwork"
  }
}
