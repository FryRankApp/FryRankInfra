variable "cloudfront_web_acl_arn" {
  description = "ARN of the Web ACL to attach to the CloudFront distribution (WAFv2)"
  type        = string
  default     = ""
}
