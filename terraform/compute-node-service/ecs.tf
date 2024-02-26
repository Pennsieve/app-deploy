// ECS Cluster
resource "aws_kms_key" "ecs_cluster" {
  description             = "ecs_cluster_kms_key"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name = "ecs-cluster-log-${random_uuid.val.id}"
}

resource "aws_ecs_cluster" "pipeline_cluster" {
  name = "pipeline-cluster-${random_uuid.val.id}"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs_cluster.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_cluster.name
      }
    }
  }
}

// ECS Task definition
resource "aws_ecs_task_definition" "pipeline" {
  family                = "pipeline-${random_uuid.val.id}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  task_role_arn      = aws_iam_role.task_role_for_ecs_task.arn
  execution_role_arn = aws_iam_role.execution_role_for_ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "pipeline-${random_uuid.val.id}"
      image     = aws_ecr_repository.app.repository_url
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/pipeline/${random_uuid.val.id}"
          awslogs-region = "us-east-1"
          awslogs-stream-prefix = "ecs"
          awslogs-create-group = "true"
        }
      }
    }
  ])
}