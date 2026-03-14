# AWS Region
variable "aws_region" {
    type = string
    default = "us-east-1"
    description = "The AWS region to deploy resources in"
}

# Project name: watchdog-aws
variable "project_name" {
    type = string
    default = "watchdog-aws"
    description = "The name of the project"
}

# Check interval times in minutes
variable "check_time" {
    type = number
    default = 5
    description = "Every 'check_time' minutes the web will be checked"
}

# Email: Intentionally no default to avoid hardcoding the email address
variable "email_notification" {
    type = string
    description = "Email to receive alerts when a web comes down"
}