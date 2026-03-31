#---------------------------------------------------------------
#                         VARIABLES
#---------------------------------------------------------------

# Región de AWS
variable "aws_region" {
    type = string
    default = "us-east-1"
    description = "The AWS region to deploy resources in"
}

# Nombre del Proyecto: Watchdog-AWS
variable "project_name" {
    type = string
    default = "watchdog"
    description = "Nombre del Proyecto"
}

# Environment: Fase del Ciclo de Vida del proyecto
variable "environment" {
    type = string
    default = "Dev"
    description = "El entorno de despliegue (Dev, Test, Prod)"
}

# Intervalo de tiempo en minutos para chequear una página web
variable "check_time" {
    type = number
    default = 5
    description = "Intervalo de tiempo en minutos para chequear una página web"
}

# Email: No se especifica ningún valor predeterminado para evitar hardcodear la dirección de correo electrónico
variable "email_notification" {
    type = string
    description = "Email para recibir las alertas cuando una página web cae"
}