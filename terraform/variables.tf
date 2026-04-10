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

# Entorno: Fase del Ciclo de Vida del proyecto
variable "stage" {
    type = string
    default = "prod"
    description = "El entorno de despliegue de la infraestructura (dev, test, prod)"
}

# Frecuencia en minutos para chequear una página web
variable "check_time" {
    type = number
    default = 5
    description = "Frecuencia en minutos para ejecutar el Watchdog"
}

# Email: No se especifica ningún valor predeterminado para evitar hardcodear la dirección de correo electrónico
variable "email_notification" {
    type = string
    description = "Email para recibir las alertas cuando una página web cae"
}