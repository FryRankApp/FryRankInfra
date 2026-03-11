variable "cloudfront_web_acl_name" {
  description = "Name of the CloudFront-created Web ACL to import"
  type        = string
  default     = ""
}

variable "cloudfront_web_acl_arn" {
  description = "ARN of the Web ACL to attach to the CloudFront distribution (WAFv2)"
  type        = string
  default     = ""
}
