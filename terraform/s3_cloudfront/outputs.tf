output "website_bucket_name" {
  description = "Name of the private S3 bucket used by the static website"
  value       = aws_s3_bucket.static_website.id
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution serving the website"
  value       = aws_cloudfront_distribution.static_website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name, without a scheme"
  value       = aws_cloudfront_distribution.static_website.domain_name
}

output "website_url" {
  description = "HTTPS URL of the static website"
  value       = "https://${aws_cloudfront_distribution.static_website.domain_name}"
}