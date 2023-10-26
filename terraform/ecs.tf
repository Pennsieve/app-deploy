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
  cpu                      = 1024
  memory                   = 2048
  task_role_arn      = var.task_role_arn
  execution_role_arn = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "pipeline-${random_uuid.val.id}"
      image     = "${data.aws_ecr_repository.fargate_task.repository_url}:demo"
      cpu       = 10
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      mountPoints = [
        {
          sourceVolume = "pipeline-storage-${random_uuid.val.id}"
          containerPath = "/mnt"
          readOnly = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/pipeline/${random_uuid.val.id}"
          awslogs-region = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group = "true"
        }
      }
    }
  ])

  volume {
    name = "pipeline-storage-${random_uuid.val.id}"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.pipeline.id
      root_directory          = "/"
    }
  }
}