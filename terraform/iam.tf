# Role for all the lambdas

resource "aws_iam_role" "lambda_role" {
    name = "${var.project_name}-lambda-role"

    # Trust policy (who can use this role)
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

# Attached Policies

# Pre-configured policy
# Permissions: CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "rn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policies
# Permissions: DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb" {
    name = "${var.project_name}-lambda-dynamodb"
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "dynamodb:PutItem",
                    "dynamodb:GetItem",
                    "dynamodb:Updateitem",
                    "dynamodb:Scan",
                    "dynamodb:Query"
                ]
                Resource = aws_dynamodb_table.websites.arn
            }
        ]
    })
}

# Permissions: SNS
resource "aws_iam_role_policy" "lambda_sns" {
  name = "${var.project_name}-lambda-sns"
  role = aws_iam_role.lambda_role.id

  policy = jsondecode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = "sns:Publish"  # To send mails when websites comes down
            Resource = aws_sns_topic.watchdog_alerts.arn
        }
    ]
  })
}