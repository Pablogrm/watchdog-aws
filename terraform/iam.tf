# ====================================================================
#                           IAM
# ====================================================================


# ====================================================================
# EXECUTION ROLES (Trust Policies)
# Define which AWS services are authorized to assume these roles
# ====================================================================

# --- Role for Lambda Watchdog ---
resource "aws_iam_role" "lambda_watchdog_role" {
  name = "lambda-watchdog-role"

  # Trust Policy: Strictly allows the Lambda service to assume this role
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


# --- Role for Lambda API ---
resource "aws_iam_role" "lambda_api_role" {
  name = "lambda-api-role"

  # Trust Policy: Strictly allows the Lambda service to assume this role
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


# --- Role for EventBridge Scheduler ---
resource "aws_iam_role" "scheduler_role" {
  name = "eventbridge-scheduler-role"

  # Trust Policy: Strictly allows the Scheduler service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

# ====================================================================
# PERMISSIONS POLICIES (Permissions Policies)
# Define which specific actions the created roles can perform
# ====================================================================

# --- Managed Policies (AWS Managed Policies) ---

# Basic permissions for Lambda Watchdog to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "watchdog_logs" {
  role       = aws_iam_role.lambda_watchdog_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Basic permissions for Lambda API to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "api_logs" {
  role       = aws_iam_role.lambda_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Inline Policies ---

# --------------------------------------------------------------------
# LAMBDA WATCHDOG POLICIES
# --------------------------------------------------------------------

# Permissions for the Watchdog Lambda function to access DynamoDB tables
resource "aws_iam_role_policy" "watchdog_dynamodb" {
  name = "watchdog-dynamodb-policy"
  role = aws_iam_role.lambda_watchdog_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # The Watchdog only needs to READ which websites to monitor in the inventory table
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.websites_inventory.arn
      },
      {
        # The Watchdog only needs to WRITE the ping results in the logs table
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.websites_logs.arn
      }
    ]
  })
}

# Permissions to publish service downtime alerts
resource "aws_iam_role_policy" "watchdog_sns" {
  name = "watchdog-sns-policy"
  role = aws_iam_role.lambda_watchdog_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.watchdog_alerts.arn
      }
    ]
  })
}


# --------------------------------------------------------------------
# POLICIES FOR THE API
# --------------------------------------------------------------------

# Database permissions for the API (Full CRUD on inventory table, Read-only on logs table)
resource "aws_iam_role_policy" "api_dynamodb" {
  name = "api-dynamodb-policy"
  role = aws_iam_role.lambda_api_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # The API needs full CRUD to manage the inventory of websites to monitor
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.websites_inventory.arn
      },
      {
        # The API only needs to READ the history to display it in React
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.websites_logs.arn,
          "${aws_dynamodb_table.websites_logs.arn}/index/*"
        ]
      }
    ]
  })
}


# --------------------------------------------------------------------
# POLICIES FOR EVENTBRIDGE SCHEDULER
# --------------------------------------------------------------------

# Permissions for EventBridge Scheduler to invoke the Lambda Watchdog function
resource "aws_iam_role_policy" "scheduler_invoke_policy" {
  name = "scheduler-invoke-lambda-policy"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.lambda_watchdog.arn
      }
    ]
  })
}