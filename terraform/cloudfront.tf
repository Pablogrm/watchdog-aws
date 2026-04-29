#---------------------------------------------------------------
#                       CLOUDFRONT
#---------------------------------------------------------------


# Origin Access Control (OAC) para permitir que CloudFront acceda al bucket S3 de forma segura, evitando exponer el bucket públicamente
resource "aws_cloudfront_origin_access_control" "watchdog_oac" {
    name = "watchdog-oac"
    description = "Origin Access Control para permitir que CloudFront acceda al bucket S3"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}


# CloudFront Distribution para servir el contenido del bucket S3 
resource "aws_cloudfront_distribution" "watchdog_cloudfront_distribution" {
    # Configuración del Origen (Conexión con el Bucket de S3)
    origin {
        domain_name = aws_s3_bucket.watchdog_bucket.bucket_regional_domain_name
        origin_access_control_id = aws_cloudfront_origin_access_control.watchdog_oac.id
        origin_id = aws_s3_bucket.watchdog_bucket.id
    }

    enabled = true
    is_ipv6_enabled = true
    default_root_object = "index.html"

    # Comportamiento por defecto (Cache y Protocolos)
    default_cache_behavior {
        allowed_methods = ["GET", "HEAD", "OPTIONS"]
        cached_methods = ["GET", "HEAD", "OPTIONS"]
        target_origin_id = aws_s3_bucket.watchdog_bucket.id

        # Redirigimos automáticamente a HTTPS para garantizar la seguridad en la comunicación
        viewer_protocol_policy = "redirect-to-https"

        forwarded_values {
            query_string = false

            cookies {
                forward = "none"
            }
        }

        # Tiempos de vida de la caché (en segundos)
        min_ttl                = 0
        default_ttl            = 3600  # 1 hora
        max_ttl                = 86400 # 24 horas
    }

    # --- Configuración para React Router ---
    # Si un usuario entra a /dashboard o /logs, S3 dará error 404/403 
    # Estas reglas interceptan el error y devuelven el index.html con un código 200 
    # 404 No encontrado -> Redirige a index.html para que React Router maneje la ruta
    custom_error_response {
        error_code = 404
        response_code = 200
        response_page_path = "/index.html"
        error_caching_min_ttl = 10
    }

    # 403 Prohibido (cuando S3 bloquea el acceso directo a rutas no existentes) -> Redirige a index.html para que React Router maneje la ruta
    custom_error_response {
        error_code = 403
        response_code = 200
        response_page_path = "/index.html"
        error_caching_min_ttl = 10
    }

    # Optimizado para servir contenido estático a nivel global con el precio más bajo (PriceClass_100 incluye solo las regiones más cercanas a Europa y América del Norte)
    price_class = "PriceClass_100"

    # Restricciones geográficas (Ninguna por ahora)
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

  # Certificado SSL (Usamos el certificado estándar de CloudFront *.cloudfront.net)
    viewer_certificate {
        cloudfront_default_certificate = true
    }

}