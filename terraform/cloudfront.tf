#---------------------------------------------------------------
#                       CLOUDFRONT
#---------------------------------------------------------------

# Usamos Origin Access Identity (OAI) para que Cloudfront pueda acceder al bucket de S3 de forma segura sin exponerlo públicamente
# No podemos usar OAC debido al uso de una cuenta de laboratorio aws academy, cuya configuración no permite crear OACs, por lo que usamos OAI que es compatible con cualquier cuenta de AWS
resource "aws_cloudfront_origin_access_identity" "watchdog_oai" {
    comment = "OAI para que Cloudfront acceda al bucket de S3"
}

# CloudFront Distribution para servir el contenido del bucket S3 
resource "aws_cloudfront_distribution" "watchdog_cloudfront_distribution" {
    # Configuración del Origen (Conexión con el Bucket de S3)
    origin {
        domain_name = aws_s3_bucket.watchdog_bucket.bucket_regional_domain_name
        origin_id = aws_s3_bucket.watchdog_bucket.id

        s3_origin_config {
          origin_access_identity = aws_cloudfront_origin_access_identity.watchdog_oai.cloudfront_access_identity_path
        }
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