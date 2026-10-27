locals {
  # "POST /ticket" => { method = "POST", path = "/ticket" }
  route_parts = {
    for key in keys(var.routes) : key => {
      method = split(" ", key)[0]
      path   = split(" ", key)[1]
    }
  }
}

resource "aws_apigatewayv2_api" "goundwork_api_gateway" {
  name          = var.api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }

  tags = {
    Project = "groundwork"
  }
}

# One integration, route and invoke permission per entry in var.routes.
resource "aws_apigatewayv2_integration" "groundwork_integration" {
  for_each = var.routes

  api_id                 = aws_apigatewayv2_api.goundwork_api_gateway.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "groundwork_route" {
  for_each = var.routes

  api_id    = aws_apigatewayv2_api.goundwork_api_gateway.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.groundwork_integration[each.key].id}"
}

resource "aws_lambda_permission" "groundwork_route_permission" {
  for_each = var.routes

  statement_id  = "AllowAPIGatewayInvoke-${replace(replace(each.key, " ", "_"), "/", "_")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.goundwork_api_gateway.execution_arn}/*/${local.route_parts[each.key].method}${local.route_parts[each.key].path}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.goundwork_api_gateway.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
  }

  tags = {
    Project = "groundwork"
  }
}
