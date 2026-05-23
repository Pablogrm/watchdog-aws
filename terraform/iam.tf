# ====================================================================
#                           IAM
# ====================================================================


# ====================================================================
# 1. ROLES DE EJECUCIÓN (Trust Policies)
# Define qué servicios de AWS están autorizados a asumir estos roles
# ====================================================================
# Rol principal para las funciones Lambda
resource "aws_iam_role" "lambda_role" {
    name = "lambda-role"

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

# Rol específico para EventBridge Scheduler
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
# 2. POLÍTICAS DE PERMISOS (Permissions Policies)
# Define qué acciones específicas pueden realizar los roles creados
# ====================================================================

# --- 2.1 Políticas Gestionadas (AWS Managed Policies) ---
# Se utiliza un 'attachment' para enlazar una política global preexistente de AWS.

# Permisos básicos para que Lambda pueda escribir logs en CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- 2.2 Políticas en Línea (Inline Policies) ---
# Se utiliza 'aws_iam_role_policy' para incrustar la política directamente dentro del rol sin crear una política independiente.

# Permisos para leer y escribir en las tablas de DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb" {
    name = "lambda-dynamodb-policy"
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "dynamodb:PutItem",
                    "dynamodb:GetItem",
                    "dynamodb:UpdateItem",
                    "dynamodb:DeleteItem",
                    "dynamodb:Scan",
                    "dynamodb:Query"
                ]
                Resource = [ 
                    # Acceso a la tabla de inventario
                    aws_dynamodb_table.websites_inventory.arn,

                    # Acceso a la tabla de logs e índices secundarios globales (GSI)
                    aws_dynamodb_table.websites_logs.arn,
                    "${aws_dynamodb_table.websites_logs.arn}/index/*"
                ]    
            }
        ]
    })
}

# Permisos para publicar alertas de caída de servicio en el topic de SNS (enviar alertas por email)
resource "aws_iam_role_policy" "lambda_sns" {
  name = "lambda-sns-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = "sns:Publish"  # Permite a Lambda publicar mensajes en el topic de SNS para enviar alertas por email
            Resource = aws_sns_topic.watchdog_alerts.arn
        }
    ]
  })
}

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