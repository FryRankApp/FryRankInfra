# CloudFront distribution (logging always enabled)
# This file configures the CloudFront distribution and ensures the S3 log bucket
# resources are created before CloudFront (so CloudFront can write logs).
#
# Note: The S3 log bucket and its ownership/ACL/policy are defined in
# `stack/frontend-s3.tf`. The distribution depends on those resources so that
# CloudFront logging won't fail due to timing/order issues.

resource "aws_cloudfront_distribution" "spa_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = local.account_id == "390844755099" ? ["beta.fryrank.app"] : local.account_id == "832016013924" ? ["fryrank.app", "www.fryrank.app"] : []
  tags                = local.tags

  # Ensure the S3 log bucket, ownership controls, ACL and policy are created
  # before creating the CloudFront distribution so that CloudFront can write logs.
  # Also wait for ACM certificate validation to complete.
  depends_on = [
    aws_s3_bucket.log_bucket,
    aws_s3_bucket_ownership_controls.log_bucket,
    aws_s3_bucket_acl.log_bucket,
    aws_s3_bucket_policy.log_bucket,
    aws_acm_certificate_validation.fryrank
  ]

  # Configure logging (always enabled)
  logging_config {
    bucket          = aws_s3_bucket.log_bucket.bucket_domain_name
    include_cookies = false
    prefix          = "cloudfront-logs/"
  }

  origin {
    domain_name              = aws_s3_bucket.spa_bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.spa_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin" # Match CloudFormation's origin ID
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Handle SPA routing by redirecting common error responses to index.html
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
    acm_certificate_arn      = aws_acm_certificate.fryrank.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_origin_access_control" "spa_oac" {
  name                              = "${local.name}-spa-oac"
  description                       = "OAC for ${local.name} SPA"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  origin_access_control_origin_type = "s3"
}

# Output the CloudFront distribution URL
output "spa_url" {
  value = "https://${aws_cloudfront_distribution.spa_distribution.domain_name}"
}

# Output DNS records to add at Porkbun for custom domain
# Add these as CNAME records pointing to the CloudFront distribution
output "cloudfront_dns_records" {
  description = "DNS records to add manually at Porkbun for custom domain aliases"
  value = {
    for alias in aws_cloudfront_distribution.spa_distribution.aliases : alias => {
      type  = "CNAME"
      name  = alias
      value = aws_cloudfront_distribution.spa_distribution.domain_name
      # Add this CNAME record at Porkbun: {name} -> {value}
    }
  }
}
