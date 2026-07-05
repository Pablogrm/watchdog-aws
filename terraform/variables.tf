# ====================================================================
#                         VARIABLES
# ====================================================================


# ====================================================================
# AWS REGION
# Spain region (eu-south-2) to reduce latency and comply
# with data protection regulations.
# ====================================================================
variable "aws_region" {
  type        = string
  default     = "eu-south-2"
  description = "The AWS region to deploy resources in"
}


# ====================================================================
# PROJECT NAME
# Used as a prefix to name resources
# ====================================================================
variable "project_name" {
  type        = string
  default     = "watchdog"
  description = "Project Name"
}


# ====================================================================
# DEPLOYMENT ENVIRONMENT
# Phase of the project lifecycle (dev, test, prod)
# ====================================================================
variable "stage" {
  type        = string
  default     = "prod"
  description = "The deployment environment of the infrastructure (dev, test, prod)"
}


# ====================================================================
# CHECK FREQUENCY
# Frequency in minutes to run the Watchdog and check web pages
# ====================================================================
variable "check_time" {
  type        = number
  default     = 5
  description = "Frequency in minutes to run the Watchdog"
}


# ====================================================================
# NOTIFICATION EMAIL
# Email to receive alerts when a website goes down
# No default value is specified to avoid hardcoding
# the email address
# ====================================================================
variable "email_notification" {
  type        = string
  description = "Email to receive alerts when a website goes down"
}