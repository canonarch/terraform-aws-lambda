terraform {
  required_version = ">= 0.12"
}

# Lamba@Edge functions must be hosted in US East (N. Virginia) Region
# cf https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-requirements-limits.html#lambda-requirements-cloudfront-triggers
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
  provider = aws.us_east_1
}

data "aws_partition" "current" {
}

resource "aws_lambda_function" "lambda" {
  provider = aws.us_east_1

  function_name = var.function_name
  description   = var.description

  filename         = data.archive_file.source_code_zip.output_path
  source_code_hash = data.archive_file.source_code_zip.output_base64sha256
  publish          = true
  handler          = var.handler

  runtime     = var.runtime
  memory_size = var.memory_size

  role = aws_iam_role.lambda.arn
}

data "archive_file" "source_code_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/${var.function_name}_lambda.zip"
}

resource "aws_iam_role" "lambda" {
  name               = substr(var.function_name, 0, 64)
  assume_role_policy = data.aws_iam_policy_document.lambda_role.json
}

data "aws_iam_policy_document" "lambda_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy" "logging" {
  name   = "${var.function_name}-logging"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.logging.json
}

data "aws_iam_policy_document" "logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*",
    ]
  }
}

