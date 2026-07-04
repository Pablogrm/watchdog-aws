# ============================================================================
#                       S3 BUCKET
# ============================================================================


# ============================================================================
# USUARIO Y REGIÓN ACTUAL
# Obtenemos el ID de la cuenta y la región actual para construir nombres 
# únicos para los recursos
# ============================================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# ============================================================================
# DOCUMENTOS DE POLÍTICA DE IAM
# Para permitir que CloudFront acceda a los objetos del bucket (IAM Policy)
# ============================================================================
data "aws_iam_policy_document" "watchdog_bucket_policy_allow_cloudfront" {
    statement {
        # Statement ID para identificar esta declaración de permisos
        sid = "AllowCloudFrontServicePrincipal"

        effect = "Allow"
        actions = ["s3:GetObject"]
        resources = ["${aws_s3_bucket.watchdog_bucket.arn}/*"]

        principals {
            type = "Service"
            identifiers = ["cloudfront.amazonaws.com"]
        }

        condition {
            test = "StringEquals"
            variable = "AWS:SourceArn"
            values = [aws_cloudfront_distribution.watchdog_cloudfront_distribution.arn]
        }
    }
}


# ============================================================================
# BUCKET DE S3
# Para almacenar el frontend de React (contenido estático)
# ============================================================================
resource "aws_s3_bucket" "watchdog_bucket" {
    bucket = "${var.project_name}-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
    # Para poder eliminar el bucket aunque tenga objetos dentro
    force_destroy = true
}


# ============================================================================
# BLOQUEO DE ACCESO PÚBLICO AL BUCKET
# Bloqueamos el acceso público al bucket para garantizar la seguridad
# ============================================================================
resource "aws_s3_bucket_public_access_block" "watchdog_bucket_public_access_block" {
    bucket = aws_s3_bucket.watchdog_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "watchdog_bucket_policy" {
    bucket = aws_s3_bucket.watchdog_bucket.id
    policy = data.aws_iam_policy_document.watchdog_bucket_policy_allow_cloudfront.json
}