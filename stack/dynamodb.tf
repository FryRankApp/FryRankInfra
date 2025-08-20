# DynamoDB table for user metadata
resource "aws_dynamodb_table" "user_metadata" {
  name         = "${local.name}-user-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "accountId"

  attribute {
    name = "accountId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Description = "DynamoDB table for user metadata"
    }
  )
}

# Mega table for reviews and aggregate review information
resource "aws_dynamodb_table" "rankings" {
  name         = "${local.name}-rankings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "restaurantId"  # Primary partition key
  range_key    = "identifier"   # Primary sort key

  # Reviews for account
  global_secondary_index {
    name               = "accountId-time-index"
    hash_key           = "accountId"
    range_key          = "isoDateTime"
    projection_type    = "ALL"
  }

  # Reviews for restaurant
  global_secondary_index {
    name               = "restaurantId-time-index"
    hash_key           = "restaurantId"
    range_key          = "isoDateTime"
    projection_type    = "ALL"
  }

  # Recent reviews
  global_secondary_index {
    name               = "recent-reviews-index"
    hash_key           = "isReview"
    range_key          = "isoDateTime"
    projection_type    = "ALL"
  }

  attribute {
    name = "identifier"
    type = "S"
  }

  attribute {
    name = "restaurantId"
    type = "S"
  }

  attribute {
    name = "isoDateTime"
    type = "S"
  }

  attribute {
    name = "accountId"
    type = "S"
  }

  attribute {
    name = "isReview"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
  
  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Description = "DynamoDB mega table for restaurant reviews and aggregate statistics"
    }
  )
}

data "aws_iam_policy_document" "dynamodb_access_policy_document" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem"
    ]
    resources = [
      aws_dynamodb_table.rankings.arn,
      "${aws_dynamodb_table.rankings.arn}/index/*",  # This is for GSIs
      aws_dynamodb_table.user_metadata.arn
    ]
  }
}

resource "aws_iam_role_policy" "dynamodb_access_policy" {
  name   = "lambda-dynamodb-access"
  role   = aws_iam_role.lambda_execution_role.id
  policy = data.aws_iam_policy_document.dynamodb_access_policy_document.json
}