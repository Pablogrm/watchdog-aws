
#---------------------------------------------------------------
#             SNS (Simple Notification Service)
#---------------------------------------------------------------


# Tema para las alertas lanzadas por el sistema Watchdog
resource "aws_sns_topic" "watchdog_alerts" {
    name = "${var.project_name}-downtime-alerts-topic"
}

# Subscripción de email para el tema
resource "aws_sns_topic_subscription" "email_alert" {
    topic_arn = aws_sns_topic.watchdog_alerts.arn
    protocol = "email"
    endpoint = var.email_notification
}