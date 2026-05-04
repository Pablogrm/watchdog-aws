#---------------------------------------------------------------
#                  EVENTBRIDGE (SCHEDULER)
#---------------------------------------------------------------

resource "aws_scheduler_schedule" "watchdog_scheduler" {
    name = "watchdog-scheduler"

    flexible_time_window {
      mode = "OFF"
    }

    schedule_expression = "rate(${var.check_time} minutes)"

    target {
      arn = aws_lambda_function.lambda_watchdog.arn
      role_arn = aws_iam_role.scheduler_role.arn
    }

    description = "Trigger de lamda-watchdog, se invocará cada ${var.check_time} minutos"
}