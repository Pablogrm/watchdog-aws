#---------------------------------------------------------------
#                         LAMBDA
#---------------------------------------------------------------


data "archive_file" "code_zip" {
    type = "zip"
    source_file = "${path.root}/../src/watchdog.py"
    output_path = "${path.root}/../src/watchdog.zip"
}

resource "aws_lambda_function" "lambda-watchdog" {
  function_name = "lambda-watchdog"
  role = data.aws_iam_role.lab_role.arn
  filename = data.archive_file.code_zip.output_path
  handler = "watchdog.lambda_handler"
  runtime = "python3.10"

  environment {
  variables = {
    SNS_TOPIC_ARN = aws_sns_topic.watchdog_alerts.arn
  }
}
}