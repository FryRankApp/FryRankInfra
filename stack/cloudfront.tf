# CloudFront origin access control
resource "aws_cloudfront_origin_access_control" "spa_oac" {
  name                              = "${local.name}-spa-oac"
  description                       = "OAC for ${local.name} SPA"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# CloudFront distribution
resource "aws_cloudfront_distribution" "spa_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  tags                = local.tags

  # Configure logging
  logging_config {
    bucket          = aws_s3_bucket.log_bucket.bucket_domain_name
    include_cookies = false
    prefix          = "cloudfront-logs/"
  }

  origin {
    domain_name              = aws_s3_bucket.spa_bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"  # Match CloudFormation's origin ID
    origin_access_control_id = aws_cloudfront_origin_access_control.spa_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"  # Match CloudFormation's origin ID
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Handle SPA routing by redirecting all paths to index.html
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

# Output the CloudFront distribution URL
output "spa_url" {
  value = "https://${aws_cloudfront_distribution.spa_distribution.domain_name}"
}
