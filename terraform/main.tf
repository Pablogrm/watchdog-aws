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

    # Global tags applied automatically to all resources created by this provider
    # This ensures traceability, standardizes governance, and follows the DRY (Don't Repeat Yourself) principle
    default_tags {
      tags = {
        Project = var.project_name
        Environment = var.environment
        ManagedBy = "terraform"
      }
    }
}
