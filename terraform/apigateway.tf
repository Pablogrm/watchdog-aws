# ============================================================================
#                             API GATEWAY
# ============================================================================


# ============================================================================
# API GATEWAY REST API
# ============================================================================
resource "aws_api_gateway_rest_api" "watchdog_api" {
  name        = "${var.project_name}-api"
  description = "REST API Gateway for Watchdog"
}


# ============================================================================
# COGNITO AUTHORIZER
# ============================================================================
resource "aws_api_gateway_authorizer" "watchdog_cognito_authorizer" {
  name        = "${var.project_name}-${var.stage}-cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.watchdog_api.id

  type = "COGNITO_USER_POOLS"

  provider_arns = [
    aws_cognito_user_pool.watchdog_user_pool.arn
  ]

  identity_source = "method.request.header.Authorization"
}


# ============================================================================
# RESOURCE 1: /webs
# To manage the web pages that will be checked
# ============================================================================
resource "aws_api_gateway_resource" "watchdog_webs_resource" {
  rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
  parent_id   = aws_api_gateway_rest_api.watchdog_api.root_resource_id
  path_part   = "webs"
}

# HTTP Methods: GET, POST and DELETE (To get, add and delete websites)
locals {
  webs_methods = toset(["GET", "POST", "DELETE"])
}

resource "aws_api_gateway_method" "webs_methods" {
  for_each = local.webs_methods

  rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
  resource_id = aws_api_gateway_resource.watchdog_webs_resource.id
  http_method = each.value

  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.watchdog_cognito_authorizer.id
}

resource "aws_api_gateway_integration" "watchdog_webs_integrations" {
  for_each = local.webs_methods

  rest_api_id             = aws_api_gateway_rest_api.watchdog_api.id
  resource_id             = aws_api_gateway_resource.watchdog_webs_resource.id
  http_method             = aws_api_gateway_method.webs_methods[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_api.invoke_arn
}

resource "aws_api_gateway_method" "webs_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.watchdog_api.id
  resource_id   = aws_api_gateway_resource.watchdog_webs_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "webs_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.watchdog_api.id
  resource_id             = aws_api_gateway_resource.watchdog_webs_resource.id
  http_method             = aws_api_gateway_method.webs_options_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_api.invoke_arn
}


# ============================================================================
# RESOURCE 2: /logs
# To get the history of website checks
# ============================================================================
resource "aws_api_gateway_resource" "watchdog_logs_resource" {
  rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
  parent_id   = aws_api_gateway_rest_api.watchdog_api.root_resource_id
  path_part   = "logs"
}

# HTTP METHOD 1: OPTIONS (To allow CORS to pass)
resource "aws_api_gateway_method" "logs_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.watchdog_api.id
  resource_id   = aws_api_gateway_resource.watchdog_logs_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integration with Lambda
resource "aws_api_gateway_integration" "logs_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.watchdog_api.id
  resource_id             = aws_api_gateway_resource.watchdog_logs_resource.id
  http_method             = aws_api_gateway_method.logs_options_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_api.invoke_arn
}


# HTTP METHOD 2: GET (To get the logs of the websites)
resource "aws_api_gateway_method" "logs_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.watchdog_api.id
  resource_id   = aws_api_gateway_resource.watchdog_logs_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.watchdog_cognito_authorizer.id
}

# Integration with Lambda
resource "aws_api_gateway_integration" "logs_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.watchdog_api.id
  resource_id             = aws_api_gateway_resource.watchdog_logs_resource.id
  http_method             = aws_api_gateway_method.logs_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_api.invoke_arn
}


# ============================================================================
# RESOURCE 3: /interval
# To get the current Lambda check interval
# ============================================================================
resource "aws_api_gateway_resource" "watchdog_interval_resource" {
  rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
  parent_id   = aws_api_gateway_rest_api.watchdog_api.root_resource_id
  path_part   = "interval"
}


# HTTP METHOD 1: OPTIONS (To allow CORS to pass)
resource "aws_api_gateway_method" "interval_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.watchdog_api.id
  resource_id   = aws_api_gateway_resource.watchdog_interval_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integration with Lambda
resource "aws_api_gateway_integration" "interval_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.watchdog_api.id
  resource_id             = aws_api_gateway_resource.watchdog_interval_resource.id
  http_method             = aws_api_gateway_method.interval_options_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_api.invoke_arn
}


# HTTP METHOD 2: GET (To get the current Lambda check interval)
resource "aws_api_gateway_method" "interval_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.watchdog_api.id
  resource_id   = aws_api_gateway_resource.watchdog_interval_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.watchdog_cognito_authorizer.id
}

# Integration with Lambda
resource "aws_api_gateway_integration" "interval_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.watchdog_api.id
  resource_id             = aws_api_gateway_resource.watchdog_interval_resource.id
  http_method             = aws_api_gateway_method.interval_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_api.invoke_arn
}


# ---------------------------------------------------------------------------
# LAMBDA PERMISSION: Permission for API Gateway to execute Lambda
# ---------------------------------------------------------------------------
resource "aws_lambda_permission" "apiw_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.watchdog_api.execution_arn}/*/*" # Only our API Gateway can invoke it, in any Stage (Environment) and any HTTP method
}


# ---------------------------------------------------------------------------
# DEPLOYMENT: To make the API public, we use automatic triggers to
# redeploy if resources, methods, or integrations are modified/added
# ---------------------------------------------------------------------------
resource "aws_api_gateway_deployment" "watchdog_deployment" {
  rest_api_id = aws_api_gateway_rest_api.watchdog_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_authorizer.watchdog_cognito_authorizer,

      # /webs
      aws_api_gateway_resource.watchdog_webs_resource,
      aws_api_gateway_method.webs_methods,
      aws_api_gateway_integration.watchdog_webs_integrations,
      aws_api_gateway_method.webs_options_method,
      aws_api_gateway_integration.webs_options_integration,

      # /logs
      aws_api_gateway_resource.watchdog_logs_resource,
      aws_api_gateway_method.logs_options_method,
      aws_api_gateway_method.logs_get_method,
      aws_api_gateway_integration.logs_options_integration,
      aws_api_gateway_integration.logs_get_integration,

      # /interval
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
# STAGE (ENVIRONMENT): To make the API public
# ---------------------------------------------------------------------------
resource "aws_api_gateway_stage" "watchdog_prod_stage" {
  deployment_id = aws_api_gateway_deployment.watchdog_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.watchdog_api.id
  stage_name    = var.stage
}