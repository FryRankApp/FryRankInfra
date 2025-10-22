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

data "aws_s3_object" "lambda_code_zip" {
  bucket = module.fryrank_lambda_function_bucket.s3_bucket_id
  key = local.lambda_function_key
}

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
  function_name = each.value.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.fryrank_api.execution_arn}/*"
}


resource "aws_lambda_function" "fryrank_api_lambdas" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  for_each      = local.lambda_functions
  function_name = each.value.name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = each.value.handler

  s3_bucket = data.aws_s3_object.lambda_code_zip.bucket
  s3_key = data.aws_s3_object.lambda_code_zip.key

  runtime = "java21"
  description = ""
  timeout = 15
  reserved_concurrent_executions = 25  # Limit total concurrent executions

  environment {
    variables = {
      "SSM_DATABASE_URI_PARAMETER_KEY" = "DATABASE_URI"
    }
  }
}