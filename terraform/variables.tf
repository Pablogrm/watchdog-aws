# AWS Region
variable "aws_region" {
    type = "S"
    default = "us-east-1"
    description = "The AWS region to deploy resources in"
}

# Project name: Watchdog-AWS
variable "project_name" {
    type = "S"
    default = "Watchdog-AWS"
    description = "The name of the project"
}

# Environment: Label the phase of the life cycle of the project
variable "environment" {
    type = "S"
    default = "Dev"
    description = "The deployment environment (Dev, Test, Prod)"
}

# Check interval time in minutes
variable "check_time" {
    type = "N"
    default = 5
    description = "Interval time in minutes the web will be checked"
}

# Email: Intentionally no default to avoid hardcoding the email address
variable "email_notification" {
    type = "S"
    description = "Email to receive alerts when a web comes down"
}