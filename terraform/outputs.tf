# ==========================================================================
#                               OUTPUTS
# ==========================================================================


# ==========================================================================
# Outputs to display relevant information after Terraform execution
# API Gateway URL
# ==========================================================================
output "api_gateway_url" {
  description = "API Gateway invocation URL"
  value       = aws_api_gateway_stage.watchdog_prod_stage.invoke_url
}


# ==========================================================================
# Nombre del bucket de S3 para el frontend
# ==========================================================================
output "s3_bucket_name" {
  description = "Nombre del S3 bucket para el alojamiento del frontend"
  value       = aws_s3_bucket.watchdog_bucket.bucket
}


# ==========================================================================
# URL pública de CloudFront (Para acceder a la web)
# ==========================================================================
output "cloudfront_url" {
  description = "URL pública de la aplicación web"
  value       = "https://${aws_cloudfront_distribution.watchdog_cloudfront_distribution.domain_name}"
}


# ==========================================================================
# Outputs related to Cognito (Authentication and Authorization)
# ==========================================================================
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.watchdog_user_pool.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.watchdog_web_client.id
}