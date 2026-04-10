#---------------------------------------------------------------
#                         LAMBDA
#---------------------------------------------------------------


# Lambda Watchdog
#---------------------------------------------------------------
# Empaquetado del código fuente de watchdog.py
# AWS Lambda exige que el código se suba comprimido, este recurso de Terraform automatiza este proceso
data "archive_file" "watchdog_zip" {
    type = "zip"
    # Como se despliega desde el directorio terraform
    # modificamos la ubicación para que salga de este directorio (/../) al principal y pueda buscar la ubicación correcta
    source_file = "${path.root}/../src/watchdog.py"   # Dónde está el código fuente original
    output_path = "${path.root}/../src/watchdog.zip"  # Dónde dejará Terraform el archivo comprimido
}

# Función Lambda Watchdog 
resource "aws_lambda_function" "lambda_watchdog" {
  function_name = "lambda-watchdog"
  role = data.aws_iam_role.lab_role.arn
  filename = data.archive_file.watchdog_zip.output_path
  handler = "watchdog.lambda_handler"
  runtime = "python3.10"
  source_code_hash = data.archive_file.watchdog_zip.output_base64sha256   # Para actualizar los archivos zip cuando cambie el código fuente de la función

  # Inyección de Variables de Entorno
  # Permite pasar información dinámica de la infraestructura de AWS al código Python
  # sin tener que escribir (hardcodear) los valores directamente en el script.
  environment {
  variables = {
    SNS_TOPIC_ARN = aws_sns_topic.watchdog_alerts.arn
  }
}
}

# Lambda API
#---------------------------------------------------------------

# Empaquetado del código fuente de api_backend.py
# AWS Lambda exige que el código se suba comprimido, este recurso de Terraform automatiza este proceso
data "archive_file" "api_backend_zip" {
    type = "zip"
    # Como se despliega desde el directorio terraform
    # modificamos la ubicación para que salga de este directorio (/../) al principal y pueda buscar la ubicación correcta
    source_file = "${path.root}/../src/api_backend.py"   # Dónde está el código fuente original
    output_path = "${path.root}/../src/api_backend.zip"  # Dónde dejará Terraform el archivo comprimido
}

# Función Lambda APi
resource "aws_lambda_function" "lambda_api" {
  function_name = "lambda-api"
  role = data.aws_iam_role.lab_role.arn
  filename = data.archive_file.api_backend_zip.output_path
  handler = "api_backend.lambda_handler"
  runtime = "python3.10"
  source_code_hash = data.archive_file.api_backend_zip.output_base64sha256    # Para actualizar los archivos zip cuando cambie el código fuente de la función
}