# CodeStar Connection to GitHub
resource "aws_codestarconnections_connection" "github" {
  count = local.isPipelineAccount

  name          = "${local.name}-github-connection"
  provider_type = "GitHub"
  tags          = local.tags
}

# CodePipeline IAM role
resource "aws_iam_role" "codepipeline_role" {
  count = local.isPipelineAccount

  name = "${local.name}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# CodePipeline IAM policy
resource "aws_iam_role_policy" "codepipeline_policy" {
  count = local.isPipelineAccount

  name = "${local.name}-pipeline-policy"
  role = aws_iam_role.codepipeline_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          module.fryrank_lambda_function_bucket.s3_bucket_arn,
          "${module.fryrank_lambda_function_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = [aws_codestarconnections_connection.github[0].arn]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [aws_codebuild_project.lambda_build.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodePipeline
resource "aws_codepipeline" "fryrank_lambda_pipeline" {
  count = local.isPipelineAccount

  name     = "${local.name}-lambda-deploy-pipeline"
  role_arn = aws_iam_role.codepipeline_role[0].arn

  artifact_store {
    location = module.fryrank_lambda_function_bucket.s3_bucket_id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github[0].arn
        FullRepositoryId = "FryRankApp/FryRankLambda"
        BranchName       = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.lambda_build.name
      }
    }
  }

  tags = local.tags
}
