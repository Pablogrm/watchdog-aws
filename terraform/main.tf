#---------------------------------------------------------------
#                          MAIN
#---------------------------------------------------------------


# Configuración de Terraform para la infraestructura AWS 
terraform {
    required_version = ">= 1.14.0"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

# Configuración del proveedor AWS
provider "aws" {
    region = var.aws_region

    # Tags globales que se aplicarán automaticamente a todos los recursos creados por este proveedor
    default_tags {
      tags = {
        Project = var.project_name
        Environment = var.environment
        ManagedBy = "terraform"
      }
    }
}
