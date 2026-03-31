#---------------------------------------------------------------
#                           IAM
#---------------------------------------------------------------


# Al trabajar en un entorno educativo como AWS Academy, utilizamos el 
# 'LabRole' preexistente que ya contiene las políticas de acceso básicas.
data "aws_iam_role" "lab_role" {
    name = "LabRole"
}