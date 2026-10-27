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

# Write-only access to this function's own log group. The group itself is created by
# Terraform below, so CreateLogGroup is deliberately not granted.
data "aws_iam_policy_document" "cloudwatch_log" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    # These actions target log streams (<group-arn>:log-stream:<name>), so ":*" is required.
    resources = ["${aws_cloudwatch_log_group.log_group.arn}:*"]
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

resource "aws_iam_role_policy" "cloudwatch_log" {
  name   = "cloudwatch-log"
  role   = aws_iam_role.bootstrap_iam_role.id
  policy = data.aws_iam_policy_document.cloudwatch_log.json
}

# ENI permissions only, so the function can run in the VPC. Unlike
# AWSLambdaVPCAccessExecutionRole, this grants no logs:* on "*".
resource "aws_iam_role_policy_attachment" "eni_management" {
  role       = aws_iam_role.bootstrap_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}

data "archive_file" "bootstrap_code" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/function.zip"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name    = var.lambda_name
    Project = "groundwork"
  }
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

  logging_config {
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.log_group.name
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }

  # The function only references the role, so Terraform can't see that the
  # permissions attached to it must exist before the first invocation.
  depends_on = [
    aws_iam_role_policy.read_master_secret,
    aws_iam_role_policy.cloudwatch_log,
    aws_iam_role_policy_attachment.eni_management,
  ]

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
    aws_iam_role_policy.cloudwatch_log,
    aws_iam_role_policy_attachment.eni_management,
  ]
}
