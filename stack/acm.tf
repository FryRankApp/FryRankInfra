##################################
# ACM Certificates
##################################

# PROD ACM Certificate (only in prod account)
resource "aws_acm_certificate" "prod" {
  count = local.account_id == "832016013924" ? 1 : 0

  provider                  = aws.us_east_1
  domain_name               = "fryrank.app"
  subject_alternative_names = ["www.fryrank.app"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags, {
    Name = "${local.name}-prod-certificate"
  })
}

resource "aws_acm_certificate_validation" "prod" {
  count = local.account_id == "832016013924" ? 1 : 0

  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.prod[0].arn
  validation_record_fqdns = [
    for dvo in aws_acm_certificate.prod[0].domain_validation_options : dvo.resource_record_name
  ]
}

output "prod_acm_validation_records" {
  description = "TXT records to add at Porkbun for prod"
  value = local.account_id == "832016013924" ? {
    for dvo in aws_acm_certificate.prod[0].domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}
}

# BETA ACM Certificate (only in beta account)
resource "aws_acm_certificate" "beta" {
  count = local.account_id == "390844755099" ? 1 : 0

  provider          = aws.us_east_1
  domain_name       = "beta.fryrank.app"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags, {
    Name = "${local.name}-beta-certificate"
  })
}

resource "aws_acm_certificate_validation" "beta" {
  count = local.account_id == "390844755099" ? 1 : 0

  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.beta[0].arn
  validation_record_fqdns = [
    for dvo in aws_acm_certificate.beta[0].domain_validation_options : dvo.resource_record_name
  ]
}

output "beta_acm_validation_records" {
  description = "TXT records to add at Porkbun for beta"
  value = local.account_id == "390844755099" ? {
    for dvo in aws_acm_certificate.beta[0].domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}
}
