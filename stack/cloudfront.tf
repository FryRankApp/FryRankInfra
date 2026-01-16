##################################
# CloudFront Distribution
##################################

# Local variables for conditional references using map lookups
locals {
  # Map aliases per account
  account_alias_map = {
    "832016013924" = ["fryrank.app", "www.fryrank.app"]
    "390844755099" = ["beta.fryrank.app"]
  }
  cf_aliases = lookup(local.account_alias_map, local.account_id, [])

  # Map ACM certificates safely using try()
  account_acm_map = {
    "832016013924" = try(aws_acm_certificate.prod[0].arn, null)
    "390844755099" = try(aws_acm_certificate.beta[0].arn, null)
  }
  acm_certificate = lookup(local.account_acm_map, local.account_id, null)

  # Map ACM validations safely
  account_acm_validation_map = {
    "832016013924" = try(aws_acm_certificate_validation.prod[0], null)
    "390844755099" = try(aws_acm_certificate_validation.beta[0], null)
  }
  acm_validation = lookup(local.account_acm_validation_map, local.account_id, null)
}

resource "aws_cloudfront_distribution" "spa_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  aliases = local.cf_aliases
  tags    = local.tags

  depends_on = [
    aws_s3_bucket.log_bucket,
    aws_s3_bucket_ownership_controls.log_bucket,
    aws_s3_bucket_acl.log_bucket,
    aws_s3_bucket_policy.log_bucket,
    local.acm_validation
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
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

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
    # Use ACM certificate if it exists; fallback to default certificate if null
    acm_certificate_arn = local.acm_certificate != null ? local.acm_certificate : null
    ssl_support_method  = local.acm_certificate != null ? "sni-only" : null
    minimum_protocol_version = local.acm_certificate != null ? "TLSv1.2_2021" : null

    cloudfront_default_certificate = local.acm_certificate == null ? true : false
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
