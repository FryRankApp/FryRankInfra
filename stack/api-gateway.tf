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