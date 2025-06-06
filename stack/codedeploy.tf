resource "aws_codedeploy_app" "lambda_codedeploy_app" {
  name             = "${local.name}-lambda-codedeploy-app"
  compute_platform = "Lambda"
}

resource "aws_iam_role" "codedeploy_service_role" {
  name = "${local.name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
  role       = aws_iam_role.codedeploy_service_role.name
}

# Add S3 permissions for CodeDeploy
resource "aws_iam_role_policy" "codedeploy_s3_policy" {
  name = "${local.name}-codedeploy-s3-policy"
  role = aws_iam_role.codedeploy_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          module.fryrank_lambda_function_bucket.s3_bucket_arn,
          "${module.fryrank_lambda_function_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Create deployment groups for each Lambda function
resource "aws_codedeploy_deployment_group" "lambda_deployment_group" {
  app_name               = aws_codedeploy_app.lambda_codedeploy_app.name
  deployment_group_name  = "${local.name}-${each.value.name}-deployment-group"
  deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
}
