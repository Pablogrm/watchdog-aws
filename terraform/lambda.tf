# AWS Lambda

# Deployment Package Generation (Automatically compresses the Python source code into a ZIP archive during the Terraform apply phase)
data "archive_file" "code_zip" {
    type        = "zip"
    source_file = "${path.module}/../src/watchdog.py"
    output_path = "${path.module}/../src/watchdog.zip"
}

# Lambda function: Health Checker 
resource "aws_lambda_function" "lambda-watchdog" {
  function_name = "${var.project_name}-health-checker-lambda"
  role          = aws_iam_role.lambda_role.arn   
  filename      = data.archive_file.code_zip.output_path
  handler       = "watchdog.lambda_handler" 
  runtime       = "python3.10"
}