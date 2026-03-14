# Terraform configuration for AWS infrastructure
terraform {
    required_version = ">= 1.14.0"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

# AWS provider configuration
provider "aws" {
    region = var.aws_region
    default_tags {
      tags = {
        Project =var.project_name
        ManagedBy = "terraform"
      }
    }
}
