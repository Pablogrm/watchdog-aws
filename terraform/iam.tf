# ====================================================================
#                           IAM
# ====================================================================


# ====================================================================
# ROLES DE EJECUCIÓN (Trust Policies)
# Define qué servicios de AWS están autorizados a asumir estos roles
# ====================================================================

# --- Rol para Lambda Watchdog ---
resource "aws_iam_role" "lambda_watchdog_role" {
    name = "lambda-watchdog-role"

    # Política de confianza: Permite estrictamente al servicio Lambda asumir este rol
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


# --- Rol para Lambda API ---
resource "aws_iam_role" "lambda_api_role" {
    name = "lambda-api-role"

    # Política de confianza: Permite estrictamente al servicio Lambda asumir este rol
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


# --- Rol para EventBridge Scheduler ---
resource "aws_iam_role" "scheduler_role" {
    name = "eventbridge-scheduler-role"

    # Política de confianza: Permite estrictamente al servicio Scheduler asumir este rol
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
# POLÍTICAS DE PERMISOS (Permissions Policies)
# Define qué acciones específicas pueden realizar los roles creados
# ====================================================================

# --- Políticas Gestionadas (AWS Managed Policies) ---

# Permisos básicos para que Lambda Watchdog pueda escribir logs en CloudWatch
resource "aws_iam_role_policy_attachment" "watchdog_logs" {
    role       = aws_iam_role.lambda_watchdog_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permisos básicos para que Lambda API pueda escribir logs en CloudWatch
resource "aws_iam_role_policy_attachment" "api_logs" {
    role       = aws_iam_role.lambda_api_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Políticas en Línea (Inline Policies) ---

# --------------------------------------------------------------------
# POLÍTICAS PARA EL WATCHDOG
# --------------------------------------------------------------------

# Permisos de base de datos para el Watchdog (Solo lectura en inventario, Solo escritura en logs)
resource "aws_iam_role_policy" "watchdog_dynamodb" {
    name = "watchdog-dynamodb-policy"
    role = aws_iam_role.lambda_watchdog_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # El Watchdog solo necesita LEER qué webs monitorizar en la tabla de inventario
                Effect = "Allow"
                Action = [
                    "dynamodb:Scan",
                    "dynamodb:GetItem"
                ]
                Resource = aws_dynamodb_table.websites_inventory.arn
            },
            {
                # El Watchdog solo necesita ESCRIBIR los resultados del ping en la tabla de logs
                Effect = "Allow"
                Action = [
                    "dynamodb:PutItem"
                ]
                Resource = aws_dynamodb_table.websites_logs.arn
            }
        ]
    })
}

# Permisos para publicar alertas de caída de servicio (Exclusivo del Watchdog)
resource "aws_iam_role_policy" "watchdog_sns" {
  name = "watchdog-sns-policy"
  role = aws_iam_role.lambda_watchdog_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = "sns:Publish"
            Resource = aws_sns_topic.watchdog_alerts.arn
        }
    ]
  })
}


# --------------------------------------------------------------------
# POLÍTICAS PARA LA API
# --------------------------------------------------------------------

# Permisos de base de datos para la API (CRUD completo en tabla de inventario, Solo lectura en tabla de logs)
resource "aws_iam_role_policy" "api_dynamodb" {
    name = "api-dynamodb-policy"
    role = aws_iam_role.lambda_api_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # La API necesita CRUD completo para gestionar el inventario de webs a monitorizar
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
                # La API solo necesita LEER el historial para mostrarlo en React
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
# POLÍTICAS PARA EVENTBRIDGE SCHEDULER
# --------------------------------------------------------------------

# Permisos para que EventBridge Scheduler pueda invocar la función Lambda Watchdog
resource "aws_iam_role_policy" "scheduler_invoke_policy"{
    name = "scheduler-invoke-lambda-policy"
    role = aws_iam_role.scheduler_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "lambda:InvokeFunction"
                Resource = aws_lambda_function.lambda_watchdog.arn
            }
        ]
    })
}