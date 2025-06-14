# CloudFront distribution for the API Gateway
resource "aws_cloudfront_distribution" "api_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  tags                = local.tags

  origin {
    domain_name = replace(aws_api_gateway_stage.fryrank_api.invoke_url, "/^https?://([^/]+).*/", "$1")
    origin_id   = "myAPIGTWOrigin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "myAPIGTWOrigin"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"  # CachingDisabled
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"  # AllViewerExceptHostHeader
    response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63"  # CORS-with-preflight-and-SecurityHeadersPolicy
  }

  custom_error_response {
    error_code         = 501
    response_code      = 501
    error_caching_min_ttl = 0
  }

  logging_config {
    bucket          = aws_s3_bucket.log_bucket.bucket_domain_name
    include_cookies = false
    prefix          = "cf-api-access-logs"
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

# Output the API CloudFront distribution URL
output "api_url" {
  value = "https://${aws_cloudfront_distribution.api_distribution.domain_name}"
} 