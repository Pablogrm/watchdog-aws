# ====================================================================
#                        CLOUDFRONT
# ====================================================================


# ====================================================================
# ORIGIN ACCESS CONTROL (OAC)
# To allow CloudFront to securely access the S3 bucket,
# avoiding exposing the bucket publicly
# ====================================================================
resource "aws_cloudfront_origin_access_control" "watchdog_oac" {
  name                              = "watchdog-oac"
  description                       = "Origin Access Control to allow CloudFront to access the S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


# ====================================================================
# CLOUDFRONT DISTRIBUTION
# To serve the content of the S3 bucket
# ====================================================================
resource "aws_cloudfront_distribution" "watchdog_cloudfront_distribution" {
  # Origin Configuration (Connection with S3 Bucket)
  origin {
    domain_name              = aws_s3_bucket.watchdog_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.watchdog_oac.id
    origin_id                = aws_s3_bucket.watchdog_bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Default behavior (Cache and Protocols)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.watchdog_bucket.id

    # We automatically redirect to HTTPS to ensure secure communication
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    # Cache TTL times (in seconds)
    min_ttl     = 0
    default_ttl = 3600  # 1 hour
    max_ttl     = 86400 # 24 hours
  }

  # --- Configuration for React Router ---
  # If a user enters /dashboard or /logs, S3 will give error 404/403
  # These rules intercept the error and return index.html with a 200 code
  # 404 Not found -> Redirects to index.html so React Router can handle the route
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # 403 Forbidden (when S3 blocks direct access to non-existent routes) -> Redirects to index.html so React Router can handle the route
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # Optimized to serve static content globally at the lowest cost (PriceClass_100 includes only regions closest to Europe and North America)
  price_class = "PriceClass_100"

  # Geographic restrictions (None for now)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate (We use CloudFront's standard certificate *.cloudfront.net)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

}