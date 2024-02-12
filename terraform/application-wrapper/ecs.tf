// ECS Task definition
resource "aws_ecs_task_definition" "application" {
  family                = "${var.app_name}-${random_uuid.val.id}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.app_cpu
  memory                   = var.app_memory
  task_role_arn      = aws_iam_role.task_role_for_app.arn
  execution_role_arn = aws_iam_role.execution_role_for_app.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-${random_uuid.val.id}"
      image     = aws_ecr_repository.app.repository_url
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      mountPoints = [
        {
          sourceVolume = "${var.app_name}-storage-${random_uuid.val.id}"
          containerPath = "/mnt/efs"
          readOnly = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/${var.app_name}/${random_uuid.val.id}"
          awslogs-region = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group = "true"
        }
      }
    }
  ])

  volume {
    name = "${var.app_name}-storage-${random_uuid.val.id}"

    efs_volume_configuration {
      file_system_id          = data.terraform_remote_state.compute_node.outputs.efs_id
      root_directory          = "/"
    }
  }
}