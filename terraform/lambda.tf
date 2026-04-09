#---------------------------------------------------------------
#                         LAMBDA
#---------------------------------------------------------------

# Empaquetado del código fuente
# AWS Lambda exige que el código se suba comprimido, este recurso de Terraform automatiza este proceso
data "archive_file" "code_zip" {
    type = "zip"
    # Como se despliega desde la carpeta terraform
    # modificamos la ubicación para que salga de esa carpeta (/../) y pueda buscar la ubicación correcta
    source_file = "${path.root}/../src/watchdog.py"   # Dónde está el código fuente original
    output_path = "${path.root}/../src/watchdog.zip"  # Dónde dejará Terraform el archivo comprimido
}

# Función Lambda Watchdog 
resource "aws_lambda_function" "lambda_watchdog" {
  function_name = "lambda-watchdog"
  role = data.aws_iam_role.lab_role.arn
  filename = data.archive_file.code_zip.output_path
  handler = "watchdog.lambda_handler"
  runtime = "python3.10"

  # Inyección de Variables de Entorno
  # Permite pasar información dinámica de la infraestructura de AWS al código Python
  # sin tener que escribir (hardcodear) los valores directamente en el script.
  environment {
  variables = {
    SNS_TOPIC_ARN = aws_sns_topic.watchdog_alerts.arn
  }
}
}

# Función Lambda API
resource "aws_lambda_function" "lambda_api" {
  function_name = "lambda-api"
  role = data.aws_iam_role.lab_role.arn
  filename = data.archive_file.code_zip.outputh_path
  handler = "api_backend.lambda_handler"
  runtime = "python3.10"
}