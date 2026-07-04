# ============================================================================
#                                 MAIN
# ============================================================================


# ============================================================================
# CONFIGURACIÓN DE TERRAFORM
# Especificamos la versión mínima de Terraform y el proveedor de AWS
# ============================================================================
terraform {
    required_version = ">= 1.14.0"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}


# ============================================================================
# CONFIGURACIÓN DEL PROVEEDOR AWS
# Especificamos la región y las etiquetas globales para los recursos
# ============================================================================
provider "aws" {
    region = var.aws_region

    # Tags globales que se aplicarán automaticamente a todos los recursos creados por este proveedor
    default_tags {
      tags = {
        Project = var.project_name
        Environment = var.stage
        ManagedBy = "terraform"
      }
    }
}
