data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "finops-rds-optimizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "finops-rds-optimizer-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:StopDBInstance",
          "rds:StartDBInstance",
          "rds:ListTagsForResource"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "rds_optimizer" {
  function_name    = "finops-rds-optimizer"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  environment {
    variables = {
      DB_INSTANCE_IDENTIFIER = aws_db_instance.postgres.identifier
    }
  }
}

resource "aws_cloudwatch_event_rule" "stop_rds_rule" {
  name                = "finops-stop-rds-daily"
  description         = "Trigger Lambda to stop RDS in the evening"
  schedule_expression = "cron(0 20 ? * * *)"
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_rds_rule.name
  target_id = "StopRDS"
  arn       = aws_lambda_function.rds_optimizer.arn
  input     = jsonencode({ action = "stop" })
}

resource "aws_lambda_permission" "allow_stop_trigger" {
  statement_id  = "AllowExecutionFromEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_optimizer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_rds_rule.arn
}

resource "aws_cloudwatch_event_rule" "start_rds_rule" {
  name                = "finops-start-rds-daily"
  description         = "Trigger Lambda to start RDS in the morning"
  schedule_expression = "cron(0 8 ? * * *)"
}

resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_rds_rule.name
  target_id = "StartRDS"
  arn       = aws_lambda_function.rds_optimizer.arn
  input     = jsonencode({ action = "start" })
}

resource "aws_lambda_permission" "allow_start_trigger" {
  statement_id  = "AllowExecutionFromEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_optimizer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_rds_rule.arn
}