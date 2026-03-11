resource "aws_wafv2_web_acl" "cloudfront_web_acl" {
  provider = aws.us_east_1

  # Use the CloudFront-created Web ACL name discovered by the deployment scripts
  name  = var.cloudfront_web_acl_name != "" ? var.cloudfront_web_acl_name : "placeholder-cloudfront-web-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-web-acl"
    sampled_requests_enabled   = true
  }

  # Don't try to manage the CloudFront-created Web ACL
  lifecycle {
    ignore_changes = all
  }
}

