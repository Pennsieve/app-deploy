// SQS queue for pipeline runs
resource "aws_sqs_queue" "terraform_queue" {
  name                      = "queue-${random_uuid.val.id}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true

  tags = {
    Environment = "${var.environment}"
  }
}