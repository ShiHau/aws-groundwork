output "invoke_url" {
  description = "Base URL of the API (no trailing slash)"
  value       = aws_apigatewayv2_api.goundwork_api_gateway.api_endpoint
}
