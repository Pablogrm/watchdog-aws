# SNS (Simple Notification Service)

# Topic for Watchdog alerts
resource "aws_sns_topic" "watchdog_alerts" {
    name = "${var.project_name}-downtime-alerts-topic"
}

# Email subscription for the topic
resource "aws_sns_topic_subscription" "email_alert" {
    topic_arn = aws_sns_topic.watchdog_alerts.arn
    protocol = "email"
    endpoint = var.email_notification
}