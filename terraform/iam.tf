#---------------------------------------------------------------
#                           IAM
#---------------------------------------------------------------


# Rol para la función Lambda, con permisos para escribir en DynamoDB, publicar en SNS y escribir logs en CloudWatch
resource "aws_iam_role" "lambda_role" {
    name = "${var.project_name}-lambda-execution-role"

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

# Políticas
# --------------------------------------------------------------------
# Políticas gestionadas por AWS (AWS Managed Policies)
# Permisos básicos para que Lambda pueda escribir logs en CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Políticas personalizadas (Custom Policies)
# Permisos para acceder a DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb" {
    name = "${var.project_name}-dynamodb-policy"
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
                    # Tabla de inventario
                    aws_dynamodb_table.websites_inventory.arn,

                    # Tabla de logs + índices para poder filtrar por GSI
                    aws_dynamodb_table.websites_logs.arn,
                    "${aws_dynamodb_table.websites_logs.arn}/index/*"
                ]    
            }
        ]
    })
}

# Permisos para publicar en SNS (enviar alertas por email)
resource "aws_iam_role_policy" "lambda_sns" {
  name = "${var.project_name}-sns-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
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