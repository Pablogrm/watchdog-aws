#---------------------------------------------------------------
#                         DYNAMODB
#---------------------------------------------------------------

# Tabla de Inventario
# Contiene las webs que se van a chequear
resource "aws_dynamodb_table" "websites_inventory" {
  name = "${var.project_name}-websites-inventory-table"
  billing_mode = "PAY_PER_REQUEST" # On-Demand
  hash_key = "url"               

  # Key attributes
  # Partition key
  attribute {
    name = "url"
    type = "S"
  }
}


# Tabla de Logs
# Contiene todos los chequeos de las paginas webs
resource "aws_dynamodb_table" "websites_logs" {
    name = "${var.project_name}-websites-logs-table"
    billing_mode = "PAY_PER_REQUEST" # On-Demand
    hash_key = "url"                 
    range_key = "timestamp"

    # Configuramos el Time To Live (TTL) para implementar el borrado automático de logs antiguos (7 dias)
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
      name = "status"
      type = "N"
    }

    # Global Secondary Index (GSI) StatusIndex: Para buscar por status code
    global_secondary_index {
      name = "StatusIndex"
      hash_key = "status"       # Partition key de GSI
      range_key = "timestamp"   # Sort key de GSI
      projection_type = "ALL"   # Proyecta todos los atributos en el index 
    }
}

