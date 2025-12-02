locals {
  lambda_function_key = "FryRankLambda.zip"
  lambda_functions = {
    get_all_reviews = {
      name = "getAllReviews",
      handler = "com.fryrank.handler.GetAllReviewsHandler"
    },
    add_new_review = {
      name = "addNewReview",
      handler = "com.fryrank.handler.AddNewReviewForRestaurantHandler"
    }
    get_aggregate_review_information = {
      name = "getAggregateReviewInformation",
      handler = "com.fryrank.handler.GetAggregateReviewInformationHandler"
    },
    get_top_reviews = {
      name = "getRecentReviews",
      handler = "com.fryrank.handler.GetRecentReviewsHandler"
    },
    get_public_user_metadata = {
      name = "getPublicUserMetadata",
      handler = "com.fryrank.handler.GetPublicUserMetadataHandler"
    },
    put_public_user_metadata = {
      name = "putPublicUserMetadata",
      handler = "com.fryrank.handler.PutPublicUserMetadataHandler"
    },
    upsert_public_user_metadata = {
      name = "upsertPublicUserMetadata",
      handler = "com.fryrank.handler.UpsertPublicUserMetadataHandler"
    }
  }
}

data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ssm_access_policy_document" {
  statement {
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      data.aws_ssm_parameter.database_uri.arn
    ]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
}

# Note: The Lambda code zip file (FryRankLambda.zip) must be uploaded to the S3 bucket
# before the Lambda functions can be created. This is typically done by:
# 1. Running your CodePipeline/CodeBuild process first, OR
# 2. Manually uploading: aws s3 cp FryRankLambda.zip s3://<bucket-name>/FryRankLambda.zip
# The bucket is created by Terraform, but the file must exist before Lambda functions are created.

resource "aws_iam_role_policy" "logging_policy" {
  name   = "lambda-logs"
  role   = aws_iam_role.lambda_execution_role.name
  policy = jsonencode({
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:logs:*:*:*",
      }
    ]
  })
}

resource "aws_iam_role_policy" "ssm_access_policy" {
  role   = aws_iam_role.lambda_execution_role.id
  policy = data.aws_iam_policy_document.ssm_access_policy_document.json
}

resource "aws_lambda_permission" "fryrank_api_lambda_permission" {
  for_each      = local.lambda_functions
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fryrank_api_lambdas[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.fryrank_api.execution_arn}/*"
  
  # Explicitly depend on the Lambda function being created first
  depends_on = [aws_lambda_function.fryrank_api_lambdas]
}


resource "aws_lambda_function" "fryrank_api_lambdas" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  for_each      = local.lambda_functions
  function_name = each.value.name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = each.value.handler

  # Reference the bucket and key directly instead of using a data source
  # This allows the bucket to be created first, then the Lambda code can be uploaded
  # and the functions created/updated in a subsequent apply
  s3_bucket = module.fryrank_lambda_function_bucket.s3_bucket_id
  s3_key    = local.lambda_function_key

  runtime = "java21"
  description = ""
  timeout = 15

  environment {
    variables = {
      "SSM_DATABASE_URI_PARAMETER_KEY" = "DATABASE_URI"
    }
  }
}