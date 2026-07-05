# ============================================================================
#                       S3 BUCKET
# ============================================================================


# ============================================================================
# CURRENT USER AND REGION
# We get the account ID and current region to build unique names
# for resources
# ============================================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# ============================================================================
# IAM POLICY DOCUMENTS
# To allow CloudFront to access bucket objects (IAM Policy)
# ============================================================================
data "aws_iam_policy_document" "watchdog_bucket_policy_allow_cloudfront" {
  statement {
    # Statement ID to identify this permission statement
    sid = "AllowCloudFrontServicePrincipal"

    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.watchdog_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.watchdog_cloudfront_distribution.arn]
    }
  }
}


# ============================================================================
# S3 BUCKET
# To store the React frontend (static content)
# ============================================================================
resource "aws_s3_bucket" "watchdog_bucket" {
  bucket = "${var.project_name}-bucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  # To be able to delete the bucket even if it has objects inside
  force_destroy = true
}


# ============================================================================
# PUBLIC ACCESS BLOCK TO BUCKET
# We block public access to the bucket to ensure security
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