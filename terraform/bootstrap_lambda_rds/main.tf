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

# Only this role can read the master secret; the application Lambda role cannot.
data "aws_iam_policy_document" "read_master_secret" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.master_secret_arn]
  }
}

resource "aws_iam_role" "bootstrap_iam_role" {
  name               = "${var.lambda_name}_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "read_master_secret" {
  name   = "read-rds-master-secret"
  role   = aws_iam_role.bootstrap_iam_role.id
  policy = data.aws_iam_policy_document.read_master_secret.json
}

resource "aws_iam_role_policy_attachment" "vpc_execution" {
  role       = aws_iam_role.bootstrap_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "archive_file" "bootstrap_code" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "bootstrap" {
  function_name    = var.lambda_name
  filename         = data.archive_file.bootstrap_code.output_path
  source_code_hash = data.archive_file.bootstrap_code.output_base64sha256
  role             = aws_iam_role.bootstrap_iam_role.arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.bootstrap_security_group_id]
  }

  environment {
    variables = {
      db_host    = var.rds_endpoint
      db_name    = var.db_name
      db_user    = var.master_username
      secret_arn = var.master_secret_arn
    }
  }

  tags = {
    Name    = "groundwork-rds-bootstrap-function"
    Project = "groundwork"
  }
}

# Runs once during apply. The handler must be idempotent: the trigger re-runs it when the code changes.
resource "aws_lambda_invocation" "bootstrap" {
  function_name = aws_lambda_function.bootstrap.function_name
  input         = jsonencode({})

  triggers = {
    code_hash = data.archive_file.bootstrap_code.output_base64sha256
  }

  depends_on = [
    aws_iam_role_policy.read_master_secret,
    aws_iam_role_policy_attachment.vpc_execution,
  ]
}
