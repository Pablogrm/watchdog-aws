# ====================================================================
#                         LAMBDA
# ====================================================================


# ====================================================================
# LAMBDA WATCHDOG
# ====================================================================

# Packaging the source code of watchdog.py
# AWS Lambda requires the code to be uploaded compressed, this Terraform resource automates this process
data "archive_file" "watchdog_zip" {
  type = "zip"
  # As it is deployed from the terraform directory
  # we modify the location to get out of this directory (/../) to the main one and can find the correct location
  source_file = "${path.root}/../src/watchdog.py"  # Where the original source code is
  output_path = "${path.root}/../src/watchdog.zip" # Where Terraform will leave the compressed file
}

# Lambda Watchdog Function 
resource "aws_lambda_function" "lambda_watchdog" {
  function_name    = "lambda-watchdog"
  role             = aws_iam_role.lambda_watchdog_role.arn
  filename         = data.archive_file.watchdog_zip.output_path
  handler          = "watchdog.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.watchdog_zip.output_base64sha256 # To update zip files when the function's source code changes
  timeout          = 60                                                 # 60 second timeout in case many pings need to be performed or websites are slow to respond, to prevent Lambda from terminating execution early and not recording logs or sending SNS alerts

  # Environment Variables Injection
  # Allows passing dynamic information from the AWS infrastructure to Python code
  # without having to write (hardcode) the values directly in the script.
  environment {
    variables = {
      TABLE_INVENTORY = aws_dynamodb_table.websites_inventory.name,
      TABLE_LOGS      = aws_dynamodb_table.websites_logs.name,
      SNS_TOPIC_ARN   = aws_sns_topic.watchdog_alerts.arn
    }
  }
}


# ====================================================================
# LAMBDA API
# ====================================================================

# Packaging the source code of api_backend.py
# AWS Lambda requires the code to be uploaded compressed, this Terraform resource automates this process
data "archive_file" "api_backend_zip" {
  type = "zip"
  # As it is deployed from the terraform directory
  # we modify the location to get out of this directory (/../) to the main one and can find the correct location
  source_file = "${path.root}/../src/api_backend.py"  # Where the original source code is
  output_path = "${path.root}/../src/api_backend.zip" # Where Terraform will leave the compressed file
}

# Lambda API Function
resource "aws_lambda_function" "lambda_api" {
  function_name    = "lambda-api"
  role             = aws_iam_role.lambda_api_role.arn
  filename         = data.archive_file.api_backend_zip.output_path
  handler          = "api_backend.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.api_backend_zip.output_base64sha256 # To update zip files when the function's source code changes

  environment {
    variables = {
      TABLE_INVENTORY   = aws_dynamodb_table.websites_inventory.name,
      TABLE_LOGS        = aws_dynamodb_table.websites_logs.name
      WATCHDOG_INTERVAL = var.check_time
      FRONTEND_URL      = "https://${aws_cloudfront_distribution.watchdog_cloudfront_distribution.domain_name}"
    }
  }
}