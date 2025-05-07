# CodeBuild IAM Role
resource "aws_iam_role" "codebuild_role" {
  name = "${local.name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# CodeBuild IAM Policy
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${local.name}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [
          "*"
        ]
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          module.fryrank_lambda_function_bucket.s3_bucket_arn,
          "${module.fryrank_lambda_function_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# CodeBuild Project
resource "aws_codebuild_project" "lambda_build" {
  name          = "${local.name}-lambda-build"
  description   = "Builds Java Lambda functions for ${local.name}"
  build_timeout = "15"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_LAMBDA_1GB"
    image                       = "aws/codebuild/amazonlinux-x86_64-lambda-standard:corretto21"
    type                        = "LINUX_LAMBDA_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = local.tags
}
