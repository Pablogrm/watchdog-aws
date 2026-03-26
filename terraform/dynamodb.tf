# DynamoDB Table

resource "aws_dynamodb_table" "websites_table" {
    name = "${var.project_name}-websites-table"
    billing_mode = "PAY_PER_REQUEST" # On-Demand
    hash_key = "url"                 
    range_key = "timestamp"          

    # 1. Key attributes of the main table
    # Partition key, website address monitorized
    attribute {
      name = "url"
      type = "S"
    }
    # Sort key, date and exact time of the measurement
    attribute {
      name = "timestamp"
      type = "S"
    }

    # 2. Key attributes required for the GSI
    # HTTP status code
    attribute {
      name = "status"
      type = "N"
    }

    # Name of the web
    attribute {
      name = "name"
      type = "N"
    }

    # Global Secondary Index (GSI) StatusIndex: To search by status code
    global_secondary_index {
      name = "StatusIndex"
      hash_key = "status"       # Partition key of GSI
      range_key = "timestamp"   # Sort key of GSI
      projection_type = "ALL"   # Projects every attribute into the index 
    }

    # Global Secondary Index (GSI) NameIndex: To search by name
    global_secondary_index {
      name = "NameIndex"
      hash_key = "name"         # Partition key of GSI
      range_key = "timestamp"   # Sort key of GSI
      projection_type = "ALL"   # Projects every attribute into the index
    }
}