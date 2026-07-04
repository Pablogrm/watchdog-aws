# ============================================================================
#                             API GATEWAY
# ============================================================================


# ============================================================================
# API GATEWAY REST API
# ============================================================================
resource "aws_api_gateway_rest_api" "watchdog_api" {
  name = "${var.project_name}-api"
  description = "REST API Gateway for Watchdog"
}


# ============================================================================
# RECURSO 1: /webs
# Para gestionar las páginas web que se van a chequear
# ============================================================================
resource "aws_api_gateway_resource" "watchdog_webs_resource" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id 
    parent_id = aws_api_gateway_rest_api.watchdog_api.root_resource_id 
    path_part = "webs"
}

# MÉTODOS HTTP: ANY (= GET,POST,DELETE,OPTIONS)
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


# ============================================================================
# RECURSO 2: /logs
# Para obtener el historial de chequeos de las webs
# ============================================================================
resource "aws_api_gateway_resource" "watchdog_logs_resource" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id 
    parent_id = aws_api_gateway_rest_api.watchdog_api.root_resource_id 
    path_part = "logs"
}

# MÉTODO HTTP 1: OPTIONS (Para que pase el CORS)
resource "aws_api_gateway_method" "logs_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.watchdog_api.id
  resource_id   = aws_api_gateway_resource.watchdog_logs_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integración con Lambda 
resource "aws_api_gateway_integration" "logs_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.watchdog_api.id
  resource_id             = aws_api_gateway_resource.watchdog_logs_resource.id
  http_method             = aws_api_gateway_method.logs_options_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_api.invoke_arn
}


# MÉTODO HTTP 2: GET (Para obtener los logs de las webs)
resource "aws_api_gateway_method" "logs_get_method" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    resource_id = aws_api_gateway_resource.watchdog_logs_resource.id
    http_method = "GET"
    authorization = "NONE"
}

# Integración con Lambda
resource "aws_api_gateway_integration" "logs_get_integration" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    resource_id = aws_api_gateway_resource.watchdog_logs_resource.id
    http_method = aws_api_gateway_method.logs_get_method.http_method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.lambda_api.invoke_arn
}


# ============================================================================
# RECURSO 3: /interval
# Para obtener el intervalo de chequeo actual de Lambda
# ============================================================================
resource "aws_api_gateway_resource" "watchdog_interval_resource" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id 
    parent_id = aws_api_gateway_rest_api.watchdog_api.root_resource_id 
    path_part = "interval"
}


# MÉTODO HTTP 1: OPTIONS (Para que pase el CORS)
resource "aws_api_gateway_method" "interval_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.watchdog_api.id
  resource_id   = aws_api_gateway_resource.watchdog_interval_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integración con Lambda 
resource "aws_api_gateway_integration" "interval_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.watchdog_api.id
  resource_id             = aws_api_gateway_resource.watchdog_interval_resource.id
  http_method             = aws_api_gateway_method.interval_options_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_api.invoke_arn
}


# MÉTODO HTTP 2: GET (Para obtener el intervalo de chequeo actual de Lambda)
resource "aws_api_gateway_method" "interval_get_method" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    resource_id = aws_api_gateway_resource.watchdog_interval_resource.id
    http_method = "GET"
    authorization = "NONE"
}

# Integración con Lambda
resource "aws_api_gateway_integration" "interval_get_integration" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    resource_id = aws_api_gateway_resource.watchdog_interval_resource.id
    http_method = aws_api_gateway_method.interval_get_method.http_method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.lambda_api.invoke_arn
}


# ---------------------------------------------------------------------------
# PERMISOS DE LAMBDA: Permisos para que API Gateway despierte a Lambda
# ---------------------------------------------------------------------------
resource "aws_lambda_permission" "apiw_lambda_permission" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_api.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.watchdog_api.execution_arn}/*/*" # Solo la podrá invocar nuestra API Gateway, en cualquier Stage (Entorno) y cualquier método http
}


# ---------------------------------------------------------------------------
# DESPLIEGUE: Para hacer la API pública, usamos triggers automáticos para 
# hacer Redeployment si se modifican / añaden recursos, métodos o integración
# ---------------------------------------------------------------------------
resource "aws_api_gateway_deployment" "watchdog_deployment" {
    rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
    triggers = {
      redeployment = sha1(jsonencode([
        # Recursos de /webs
        aws_api_gateway_resource.watchdog_webs_resource,
        aws_api_gateway_method.webs_methods,
        aws_api_gateway_integration.watchdog_webs_integration,
        
        # Recursos de /logs
        aws_api_gateway_resource.watchdog_logs_resource,
        aws_api_gateway_method.logs_options_method,
        aws_api_gateway_method.logs_get_method,
        aws_api_gateway_integration.logs_options_integration,
        aws_api_gateway_integration.logs_get_integration,

        # Recursos de /interval
        aws_api_gateway_resource.watchdog_interval_resource,
        aws_api_gateway_method.interval_options_method,
        aws_api_gateway_method.interval_get_method,
        aws_api_gateway_integration.interval_options_integration,
        aws_api_gateway_integration.interval_get_integration
      ]))
    }

    lifecycle {
      create_before_destroy = true
  }
}


# ---------------------------------------------------------------------------
# STAGE (Entorno)
# ---------------------------------------------------------------------------
resource "aws_api_gateway_stage" "watchdog_prod_stage" {
  deployment_id = aws_api_gateway_deployment.watchdog_deployment.id
  rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
  stage_name = var.stage
}