# ====================================================================
#                         VARIABLES
# ====================================================================


# ====================================================================
# REGIÓN DE AWS
# eRegión de España (eu-south-2) para reducir la latencia y cumplir 
# con la legislación de protección de datos.
# ====================================================================
variable "aws_region" {
    type = string
    default = "eu-south-2"
    description = "The AWS region to deploy resources in"
}


# ====================================================================
# NOMBRE DEL PROYECTO
# Se utiliza como prefijo para nombrar los recursos
# ====================================================================
variable "project_name" {
    type = string
    default = "watchdog"
    description = "Nombre del Proyecto"
}


# ====================================================================
# ENTORNO DE DESPLIEGUE
# Fase del Ciclo de Vida del proyecto (dev, test, prod)
# ====================================================================
variable "stage" {
    type = string
    default = "prod"
    description = "El entorno de despliegue de la infraestructura (dev, test, prod)"
}


# ====================================================================
# FRECUENCIA DE CHEQUEO
# Frecuencia en minutos para ejecutar el Watchdog y chequear las páginas web
# ====================================================================
variable "check_time" {
    type = number
    default = 5
    description = "Frecuencia en minutos para ejecutar el Watchdog"
}


# ====================================================================
# EMAIL DE NOTIFICACIÓN
# Email para recibir las alertas cuando una página web cae
# No se especifica ningún valor predeterminado para evitar hardcodear 
# la dirección de correo electrónico
# ====================================================================
variable "email_notification" {
    type = string
    description = "Email para recibir las alertas cuando una página web cae"
}