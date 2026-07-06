# ============================================================================
#                                 MAIN
# ============================================================================


# ============================================================================
# TERRAFORM CONFIGURATION
# We specify the minimum version of Terraform and the AWS provider
# ============================================================================
terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# ============================================================================
# AWS PROVIDER CONFIGURATION
# We specify the region and global tags for resources
# ============================================================================
provider "aws" {
  region = var.aws_region

  # Global tags that will be automatically applied to all resources created by this provider
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.stage
      ManagedBy   = "terraform"
    }
  }
}
