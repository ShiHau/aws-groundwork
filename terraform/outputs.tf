output "api_url" {
  description = "Base URL of the HTTP API"
  value       = module.groundwork_api_gateway.invoke_url
}

output "website_url" {
  description = "HTTPS URL of the CloudFront website"
  value       = module.groundwork_s3_cloudfront.website_url
}

output "website_bucket_name" {
  description = "Name of the private S3 bucket containing the website files"
  value       = module.groundwork_s3_cloudfront.website_bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID used for cache invalidations"
  value       = module.groundwork_s3_cloudfront.cloudfront_distribution_id
}
