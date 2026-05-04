#---------------------------------------------------------------
#                         OUTPUTS
#---------------------------------------------------------------


# Outputs para mostrar información relevante tras la ejecución de Terraform
# URL de la API Gateway
output "api_gateway_url" {
    description = "URL de invocación de la API Gateway"
    value = aws_api_gateway_stage.watchdog_prod_stage.invoke_url
}

# Nombre del bucket de S3 para el frontend
output "s3_bucket_name" {
    description = "Nombre del S3 bucket para el alojamiento del frontend"
    value = aws_s3_bucket.watchdog_bucket.bucket
}

# URL pública de CloudFront (Para acceder a la web)
output "cloudfront_url" {
    description = "URL pública de la aplicación web"
    value       = "https://${aws_cloudfront_distribution.watchdog_cloudfront_distribution.domain_name}"
}