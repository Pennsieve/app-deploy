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
  cpu                      = var.app_cpu
  memory                   = var.app_memory
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
      mountPoints = [
        {
          sourceVolume = "pipeline-storage-${random_uuid.val.id}"
          containerPath = "/mnt/efs"
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

// ECS Task definition - post processor
resource "aws_ecs_task_definition" "post-processor" {
  family                = "post-processor-${random_uuid.val.id}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.post_processor_cpu
  memory                   = var.post_processor_memory
  task_role_arn      = aws_iam_role.task_role_for_post_processor.arn
  execution_role_arn = aws_iam_role.execution_role_for_post_processor.arn

  container_definitions = jsonencode([
    {
      name      = "post-processor-${random_uuid.val.id}"
      image     = aws_ecr_repository.post-processor.repository_url
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      mountPoints = [
        {
          sourceVolume = "post-storage-${random_uuid.val.id}"
          containerPath = "/mnt/efs"
          readOnly = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/post-processor/${random_uuid.val.id}"
          awslogs-region = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group = "true"
        }
      }
    }
  ])

  volume {
    name = "post-storage-${random_uuid.val.id}"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.pipeline.id
      root_directory          = "/"
    }
  }
}

// ECS Task definition - pre processor
resource "aws_ecs_task_definition" "pre-processor" {
  family                = "pre-processor-${random_uuid.val.id}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.pre_processor_cpu
  memory                   = var.pre_processor_memory
  task_role_arn      = aws_iam_role.task_role_for_pre_processor.arn
  execution_role_arn = aws_iam_role.execution_role_for_pre_processor.arn

  container_definitions = jsonencode([
    {
      name      = "pre-processor-${random_uuid.val.id}"
      image     = aws_ecr_repository.pre-processor.repository_url
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      mountPoints = [
        {
          sourceVolume = "pre-storage-${random_uuid.val.id}"
          containerPath = "/mnt/efs"
          readOnly = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/pre-processor/${random_uuid.val.id}"
          awslogs-region = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group = "true"
        }
      }
    }
  ])

  volume {
    name = "pre-storage-${random_uuid.val.id}"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.pipeline.id
      root_directory          = "/"
    }
  }
}

// ECS Task definition - workflow manager
resource "aws_ecs_task_definition" "workflow-manager" {
  family                = "wm-${random_uuid.val.id}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.wm_cpu
  memory                   = var.wm_memory
  task_role_arn      = aws_iam_role.task_role_for_ecs_task.arn
  execution_role_arn = aws_iam_role.execution_role_for_ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "wm-${random_uuid.val.id}"
      image     = aws_ecr_repository.workflow-manager.repository_url
      environment: [
      {name: "SQS_URL", value: aws_sqs_queue.terraform_queue.id},
      { name: "TASK_DEFINITION_NAME_PRE", value: aws_ecs_task_definition.pre-processor.family},
      { name: "CONTAINER_NAME_PRE", value: aws_ecs_task_definition.pre-processor.family},
      { name: "TASK_DEFINITION_NAME_POST", value: aws_ecs_task_definition.post-processor.family},
      { name: "CONTAINER_NAME_POST", value: aws_ecs_task_definition.post-processor.family},
      { name: "PENNSIEVE_AGENT_HOME", value: var.pennsieve_agent_home},
      { name: "PENNSIEVE_UPLOAD_BUCKET", value: var.pennsieve_upload_bucket},
      { name: "SUBNET_IDS", value: local.subnet_ids},
      { name: "CLUSTER_NAME", value: aws_ecs_cluster.pipeline_cluster.name},
      { name: "SECURITY_GROUP_ID", value: aws_default_security_group.default.id},
      { name: "ENVIRONMENT", value: var.environment},
      { name: "PENNSIEVE_API_HOST", value: var.api_host},
      { name: "PENNSIEVE_API_HOST", value: var.api_host2},
      { name: "BASE_DIR", value: "/mnt/efs"},
      { name: "REGION", value: var.region}
      ],
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      mountPoints = [
        {
          sourceVolume = "wm-storage-${random_uuid.val.id}"
          containerPath = "/mnt/efs"
          readOnly = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/wm/${random_uuid.val.id}"
          awslogs-region = var.region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group = "true"
        }
      }
    }
  ])

  volume {
    name = "wm-storage-${random_uuid.val.id}"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.pipeline.id
      root_directory          = "/"
    }
  }
}

resource "aws_ecs_service" "workflow-manager" {
  name            = "wm-${random_uuid.val.id}"
  cluster         = aws_ecs_cluster.pipeline_cluster.id
  task_definition = aws_ecs_task_definition.workflow-manager.arn
  launch_type = "FARGATE"
  desired_count = 0

  network_configuration {
    subnets = local.subnet_ids_list
    assign_public_ip = true
    security_groups = [aws_default_security_group.default.id]
  }
}