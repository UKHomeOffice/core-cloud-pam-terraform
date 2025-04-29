data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "test_policy" {
  name = "AWSLambdaBasicExecutionRole"
  role = aws_iam_role.lambda_execution.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:eu-west-2:${local.account_id}:*"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:logs:eu-west-2:${local.account_id}:log-group:/aws/lambda/TEAM-SNS-handler:*"]
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect  = "Allow"
        Resouce = ["arn:aws:secretsmanager:eu-west-2:${local.account_id}:secret:TEAM-IDC-APP*"]
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = var.source_file
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "team_sns_handler" {
  architectures = ["arm64"]
  filename      = "lambda_function_payload.zip"
  function_name = var.function_name
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_execution.arn
  runtime       = "python3.13"

  source_code_hash = data.archive_file.lambda.output_base64sha256
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.team_sns_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:eu-west-2:${local.account_id}:${var.sns_topic_name}"
}

data "aws_sns_topic" "team_notifications" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = data.aws_sns_topic.team_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.team_sns_handler.arn
}
