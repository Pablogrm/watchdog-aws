# ====================================================================
#                           DYNAMODB
# ====================================================================


# ====================================================================
# INVENTORY TABLE
# Contains the websites that will be checked
# ====================================================================
resource "aws_dynamodb_table" "websites_inventory" {
  name         = "${var.project_name}-websites-inventory-table"
  billing_mode = "PAY_PER_REQUEST" # On-Demand
  hash_key     = "url"

  # Key attributes
  # Partition key
  attribute {
    name = "url"
    type = "S"
  }
}


# ====================================================================
# LOGS TABLE
# Contains all the checks of the web pages
# ====================================================================
resource "aws_dynamodb_table" "websites_logs" {
  name         = "${var.project_name}-websites-logs-table"
  billing_mode = "PAY_PER_REQUEST" # On-Demand
  hash_key     = "url"
  range_key    = "timestamp"

  # Configure Time To Live (TTL) to implement automatic deletion of old logs (7 days)
  ttl {
    attribute_name = "expiration"
    enabled        = true
  }

  # 1. Key attributes
  # Partition key
  attribute {
    name = "url"
    type = "S"
  }
  # Sort key
  attribute {
    name = "timestamp"
    type = "S"
  }

  # 2. Key attribute requerido para el GSI
  # HTTP status code
  attribute {
    name = "health_status"
    type = "S"
  }

  # Global Secondary Index (GSI) StatusIndex: Para buscar por status distinto a 200 -> ERRORES
  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "health_status" # Partition key de GSI
    range_key       = "timestamp"     # Sort key de GSI
    projection_type = "ALL"           # Proyecta todos los atributos en el index 
  }
}