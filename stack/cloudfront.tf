resource "aws_cloudfront_distribution" "spa_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # Conditional aliases based on account
  aliases = local.account_id == "832016013924" ? ["fryrank.app", "www.fryrank.app"] :
            local.account_id == "390844755099" ? ["beta.fryrank.app"] :
            []

  tags = local.tags

  depends_on = [
    aws_s3_bucket.log_bucket,
    aws_s3_bucket_ownership_controls.log_bucket,
    aws_s3_bucket_acl.log_bucket,
    aws_s3_bucket_policy.log_bucket,
    local.account_id == "832016013924" ? aws_acm_certificate_validation.prod[0] :
    local.account_id == "390844755099" ? aws_acm_certificate_validation.beta[0] : null
  ]

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
    acm_certificate_arn = local.account_id == "832016013924" ? aws_acm_certificate.prod[0].arn :
                          local.account_id == "390844755099" ? aws_acm_certificate.beta[0].arn :
                          null
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
