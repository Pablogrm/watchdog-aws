#---------------------------------------------------------------
#                       API GATEWAY
#---------------------------------------------------------------

# API Gateway REST API
resource "aws_api_gateway_rest_api" "watchdog_api" {
  name = "${var.project_name}-api"
  description = "REST API Gateway for Watchdog"
}

#---------------------------------------------------------------

# RECURSO 1: /webs
resource "aws_api_gateway_resource" "watchdog_webs_resource" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id 
    parent_id = aws_api_gateway_rest_api.watchdog_api.root_resource_id 
    path_part = "webs"
}

# Métodos http /webs: ANY (= GET,POST,DELETE,OPTIONS)
resource "aws_api_gateway_method" "webs_methods" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    resource_id = aws_api_gateway_resource.watchdog_webs_resource.id
    http_method = "ANY"
    authorization = "NONE"
}

# Integración con Lambda
resource "aws_api_gateway_integration" "watchdog_webs_integration" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    resource_id = aws_api_gateway_resource.watchdog_webs_resource.id
    http_method = aws_api_gateway_method.webs_methods.http_method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.lambda_api.invoke_arn
}

#---------------------------------------------------------------

# RECURSO 2: /logs
resource "aws_api_gateway_resource" "watchdog_logs_resource" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id 
    parent_id = aws_api_gateway_rest_api.watchdog_api.root_resource_id 
    path_part = "logs"
}

# Métodos http /logs: ANY (= GET,POST,DELETE,OPTIONS)
resource "aws_api_gateway_method" "logs_methods" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    resource_id = aws_api_gateway_resource.watchdog_logs_resource.id
    http_method = "ANY"
    authorization = "NONE"
}

# Integración con Lambda 
resource "aws_api_gateway_integration" "watchdog_logs_integration" {
  rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    resource_id = aws_api_gateway_resource.watchdog_logs_resource.id
    http_method = aws_api_gateway_method.logs_methods.http_method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.lambda_api.invoke_arn
}

#---------------------------------------------------------------

# Lambda: Permisos para que API Gateway despierte a Lambda
resource "aws_lambda_permission" "apiw_lambda_permission" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_api.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.watchdog_api.execution_arn}/*/*" # Solo la podrá invocar nuestra API Gateway, en cualquier Stage (Entorno) y cualquier método http
}

#---------------------------------------------------------------

# Despliegue: Para hacer la API pública, usamos triggers automáticos para hacer Redeployment si se modifican / añaden recursos, métodos o integración
resource "aws_api_gateway_deployment" "watchdog_deployment" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    triggers = {
       redeployment = sha1(jsonencode([
      aws_api_gateway_resource.watchdog_webs_resource,
      aws_api_gateway_method.webs_methods,
      aws_api_gateway_integration.watchdog_webs_integration,
      
      aws_api_gateway_resource.watchdog_logs_resource,
      aws_api_gateway_method.logs_methods,
      aws_api_gateway_integration.watchdog_logs_integration
    ]))
    }

    lifecycle {
      create_before_destroy = true
    }
}

# Stage (Entorno)
resource "aws_api_gateway_stage" "watchdog_prod_stage" {
  deployment_id = aws_api_gateway_deployment.watchdog_deployment.id
  rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
  stage_name = var.stage
}