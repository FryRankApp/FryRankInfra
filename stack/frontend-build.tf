resource "aws_codebuild_project" "frontend_build" {
  count        = local.isPipelineAccount
  name         = "${local.name}-frontend-build"
  description  = "Builds the React frontend and uploads to S3."
  service_role = aws_iam_role.frontend_codebuild_role[0].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
    environment_variable {
      name  = "ENV"
      value = "production"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

resource "aws_iam_role" "frontend_codebuild_role" {
  count              = local.isPipelineAccount
  name               = "${local.name}-frontend-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy[0].json
}

resource "aws_iam_role_policy_attachment" "frontend_codebuild_policy_attachment" {
  count      = local.isPipelineAccount
  role       = aws_iam_role.frontend_codebuild_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy" "frontend_codebuild_logs_policy" {
  count = local.isPipelineAccount
  name  = "${local.name}-frontend-codebuild-logs-policy"
  role  = aws_iam_role.frontend_codebuild_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.name}-frontend-build:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "frontend_codebuild_ssm_policy" {
  count = local.isPipelineAccount
  name  = "${local.name}-frontend-codebuild-ssm-policy"
  role  = aws_iam_role.frontend_codebuild_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/GOOGLE_API_KEY",
          "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/GOOGLE_AUTH_KEY",
          "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/BACKEND_SERVICE_PATH"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          "arn:aws:kms:${local.region}:${data.aws_caller_identity.current.account_id}:key/alias/aws/ssm"
        ]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${local.region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  count = local.isPipelineAccount
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "frontend_codepipeline_role" {
  count              = local.isPipelineAccount
  name               = "${local.name}-frontend-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy[0].json
}

resource "aws_iam_role_policy_attachment" "frontend_codepipeline_policy_attachment" {
  count      = local.isPipelineAccount
  role       = aws_iam_role.frontend_codepipeline_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "codepipeline_assume_role_policy" {
  count = local.isPipelineAccount
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}
