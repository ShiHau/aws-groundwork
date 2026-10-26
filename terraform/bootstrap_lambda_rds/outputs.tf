output "bootstrap_result" {
  description = "Result returned by the bootstrap function"
  value       = aws_lambda_invocation.bootstrap.result
}
