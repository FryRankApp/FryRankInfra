# S3 bucket for hosting the React SPA
resource "aws_s3_bucket" "spa_bucket" {
  bucket = "${local.name}-spa-bucket"
  tags   = local.tags
}

# S3 bucket for CloudFront logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${local.name}-spa-logs"
  tags   = local.tags
}

# Block public access to the log bucket
resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Log bucket policy to allow CloudFront log delivery
resource "aws_s3_bucket_policy" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontLogDelivery"
        Effect    = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "spa_bucket" {
  bucket = aws_s3_bucket.spa_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure lifecycle rules for the S3 bucket
resource "aws_s3_bucket_lifecycle_configuration" "spa_bucket" {
  bucket = aws_s3_bucket.spa_bucket.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {
      prefix = ""  # Apply to all objects in the bucket
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Configure CORS for the S3 bucket
resource "aws_s3_bucket_cors_configuration" "spa_bucket" {
  bucket = aws_s3_bucket.spa_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "spa_bucket" {
  bucket = aws_s3_bucket.spa_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket configuration for static website hosting
resource "aws_s3_bucket_website_configuration" "spa_bucket" {
  bucket = aws_s3_bucket.spa_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "spa_bucket_policy" {
  bucket = aws_s3_bucket.spa_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.spa_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.spa_distribution.arn
          }
        }
      }
    ]
  })
} 