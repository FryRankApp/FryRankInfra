# DynamoDB table for user metadata
resource "aws_dynamodb_table" "user_metadata" {
  name         = "${local.name}-user-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "accountId"

  deletion_protection_enabled = true

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
  hash_key     = "restaurantId" # Primary partition key
  range_key    = "identifier"   # Primary sort key

  deletion_protection_enabled = true

  # Reviews for account
  global_secondary_index {
    name            = "accountId-time-index"
    hash_key        = "accountId"
    range_key       = "isoDateTime"
    projection_type = "ALL"
  }

  # Reviews for restaurant
  global_secondary_index {
    name            = "restaurantId-time-index"
    hash_key        = "restaurantId"
    range_key       = "isoDateTime"
    projection_type = "ALL"
  }

  # Recent reviews
  global_secondary_index {
    name            = "recent-reviews-index"
    hash_key        = "isReview"
    range_key       = "isoDateTime"
    projection_type = "ALL"
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

# Per-user reaction state (thumbs up / down / heart) keyed by viewer + review
resource "aws_dynamodb_table" "reactions" {
  name         = "${local.name}-reactions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "viewerAccountId"
  range_key    = "reviewId"

  deletion_protection_enabled = true

  attribute {
    name = "viewerAccountId"
    type = "S"
  }

  attribute {
    name = "reviewId"
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
      Description = "DynamoDB table for per-user review reactions"
    }
  )
}

data "aws_iam_policy_document" "dynamodb_access_policy_document" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:TransactWriteItems",
      "dynamodb:TransactGetItems"
    ]
    resources = [
      aws_dynamodb_table.rankings.arn,
      "${aws_dynamodb_table.rankings.arn}/index/*", # This is for GSIs
      aws_dynamodb_table.user_metadata.arn,
      aws_dynamodb_table.reactions.arn,
      "${aws_dynamodb_table.reactions.arn}/index/*"
    ]
  }
}

resource "aws_iam_role_policy" "dynamodb_access_policy" {
  name   = "lambda-dynamodb-access"
  role   = aws_iam_role.lambda_execution_role.id
  policy = data.aws_iam_policy_document.dynamodb_access_policy_document.json
}