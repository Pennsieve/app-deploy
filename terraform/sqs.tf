// SQS queue for pipeline runs
resource "aws_sqs_queue" "pipeline_queue" {
  name                      = "queue-${random_uuid.val.id}"

  tags = {
    Environment = "${var.environment}"
  }
}