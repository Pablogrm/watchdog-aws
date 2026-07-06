# ====================================================================
#                        AMAZON COGNITO
# ====================================================================


# ====================================================================
#                      COGNITO USER POOL
# ====================================================================
resource "aws_cognito_user_pool" "watchdog_user_pool" {
  name                     = "${var.project_name}-user-pool-${var.stage}"
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length    = 10
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  mfa_configuration = "OFF"

  software_token_mfa_configuration {
    enabled = true
  }
}


# ====================================================================
# COGNITO USER POOL CLIENT
# ====================================================================
resource "aws_cognito_user_pool_client" "watchdog_web_client" {
  name         = "${var.project_name}-${var.stage}-web-client"
  user_pool_id = aws_cognito_user_pool.watchdog_user_pool.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
}
