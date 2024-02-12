// Cloudwatch alarm for SQS queue length

resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth_alarm" {
  alarm_name                = "messages-in-queue-alarm"
  comparison_operator      = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name              = "ApproximateNumberOfMessagesVisible"
  namespace                = "AWS/SQS"
  period                   = "60"
  statistic                = "Average"
  threshold                = "1"
  treat_missing_data       = "notBreaching"
  dimensions = {
    QueueName = "${aws_sqs_queue.pipeline_queue.name}"
  }
  alarm_description = "This metric monitors queue depth and triggers an alarm if the average number of messages in the queue is greater than or equal to 1 over a period of 60 seconds."
}