# ACM Certificate for CloudFront
# CloudFront requires certificates to be in us-east-1 region
#
# This certificate covers:
# - fryrank.app (primary domain)
# - www.fryrank.app (prod alias)
# - beta.fryrank.app (beta alias)

resource "aws_acm_certificate" "fryrank" {
  provider                = aws.us_east_1
  domain_name             = "fryrank.app"
  subject_alternative_names = ["www.fryrank.app", "beta.fryrank.app"]
  validation_method       = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags, {
    Name = "${local.name}-certificate"
  })
}

# Output DNS validation records - add these manually at Porkbun
# After adding these records, the certificate will validate automatically
output "acm_certificate_validation_records" {
  description = "DNS validation records to add manually at Porkbun"
  value = {
    for dvo in aws_acm_certificate.fryrank.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
      # Example: Add a TXT record at Porkbun with name=value
    }
  }
}

# Certificate validation - waits for DNS records to be added at Porkbun
resource "aws_acm_certificate_validation" "fryrank" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.fryrank.arn
  validation_record_fqdns = [for dvo in aws_acm_certificate.fryrank.domain_validation_options : dvo.resource_record_name]

  timeouts {
    create = "5m"
  }
}
