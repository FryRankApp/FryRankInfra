# Cost Protection and Quota Management
# This file contains quotas and limits to prevent runaway costs

# Lambda Concurrency Quota (Account-wide)
resource "aws_servicequotas_service_quota" "lambda_concurrency" {
  quota_code   = "L-2AC55022"  # Lambda concurrent executions
  service_code = "lambda"
  value        = 100           # Total account limit (was 1000 default)

  depends_on = [aws_servicequotas_service_quota.lambda_concurrency]
}

# DynamoDB On-Demand Billing Limits
resource "aws_servicequotas_service_quota" "dynamodb_read_capacity" {
  quota_code   = "L-0F9C7F7E"  # DynamoDB read capacity units
  service_code = "dynamodb"
  value        = 40000         # Maximum read capacity units

  depends_on = [aws_servicequotas_service_quota.dynamodb_read_capacity]
}

resource "aws_servicequotas_service_quota" "dynamodb_write_capacity" {
  quota_code   = "L-23A3F4F7"  # DynamoDB write capacity units  
  service_code = "dynamodb"
  value        = 40000         # Maximum write capacity units

  depends_on = [aws_servicequotas_service_quota.dynamodb_write_capacity]
}

# CloudFront Distribution Limits
# Note: CloudFront doesn't have a service quota for number of distributions
# The limit is typically 200 distributions per account by default
# We'll rely on AWS account limits and monitoring instead

# S3 Bucket Limits
resource "aws_servicequotas_service_quota" "s3_buckets" {
  quota_code   = "L-DC2B2D3D"  # S3 buckets
  service_code = "s3"
  value        = 10            # Limit to 10 buckets

  depends_on = [aws_servicequotas_service_quota.s3_buckets]
}

# Billing Alerts
resource "aws_budgets_budget" "monthly_budget" {
  name         = "fryrank-monthly-budget"
  budget_type  = "COST"
  limit_amount = "50"          # $50/month budget
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filters = {
    Service = [
      "Amazon API Gateway",
      "AWS Lambda",
      "Amazon DynamoDB", 
      "Amazon CloudFront",
      "Amazon Simple Storage Service"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80           # Alert at 80% of budget
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["your-email@example.com"]  # Update this
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100          # Alert at 100% of budget
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_email_addresses = ["your-email@example.com"]  # Update this
  }
}

# Cost Anomaly Detection
resource "aws_ce_anomaly_detector" "cost_anomaly" {
  name        = "fryrank-cost-anomaly"
  monitor_arn = aws_ce_cost_category.fryrank_cost_category.arn

  specification = "DAILY"
  frequency     = "DAILY"
}

resource "aws_ce_cost_category" "fryrank_cost_category" {
  name         = "fryrank-services"
  rule {
    value = "FryRank"
    rule {
      dimension {
        key           = "SERVICE"
        values        = [
          "Amazon API Gateway",
          "AWS Lambda", 
          "Amazon DynamoDB",
          "Amazon CloudFront",
          "Amazon Simple Storage Service"
        ]
      }
    }
  }
}
