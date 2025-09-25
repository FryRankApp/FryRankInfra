resource "aws_api_gateway_rest_api" "fryrank_api" {
  body = file("${path.module}/fryrank-openapi-spec.json")

  name = "fryrank-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "fryrank_api" {
  rest_api_id = aws_api_gateway_rest_api.fryrank_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.fryrank_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "fryrank_api" {
  deployment_id = aws_api_gateway_deployment.fryrank_api.id
  rest_api_id   = aws_api_gateway_rest_api.fryrank_api.id
  stage_name    = "beta"
}

resource "aws_api_gateway_usage_plan" "fryrank_api_usage_plan" {
  name          = "fryrank-api-usage-plan"
  description   = "quota and throtte settings for fryrank_api"

  api_stages {
    api_id = aws_api_gateway_rest_api.fryrank_api.id
    stage = aws_api_gateway_stage.fryrank_api.stage_name
  }

  quota_settings {
    limit = 50000
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 500
    rate_limit  = 100.0
  }
}