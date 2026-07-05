# ============================================================================
#                  SNS (Simple Notification Service)
# ============================================================================


# ============================================================================
# SNS TOPIC FOR ALERTS
# Topic to send email alerts when a website is down 
# ============================================================================
resource "aws_sns_topic" "watchdog_alerts" {
  name = "${var.project_name}-downtime-alerts-topic"
}


# ============================================================================
# EMAIL SUBSCRIPTION FOR ALERTS
# ============================================================================
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.watchdog_alerts.arn
  protocol  = "email"
  endpoint  = var.email_notification
}