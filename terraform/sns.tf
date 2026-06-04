# ============================================================================
#                  SNS (Simple Notification Service)
# ============================================================================


# ============================================================================
# TÓPICO DE SNS PARA ALERTAS
# Tópico para enviar alertas por email cuando una web esté caída 
# ============================================================================
resource "aws_sns_topic" "watchdog_alerts" {
    name = "${var.project_name}-alerts-topic"
}


# ============================================================================
# SUSCRIPCIÓN DE EMAIL PARA ALERTAS
# ============================================================================
resource "aws_sns_topic_subscription" "email_alert" {
    topic_arn = aws_sns_topic.watchdog_alerts.arn
    protocol = "email"
    endpoint = var.email_notification
}