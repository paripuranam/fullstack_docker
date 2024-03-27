provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "multi" {
  name = "multicontainer-cluster-terraform"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "multi" {
  family = "multicontainer-task-def-terraform"

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "paripuranam/reactapp"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 80
        }
      ]
      essential = true
      environment = [
        {
          name  = "CHOKIDAR_USEPOLLING"
          value = "true"
        }
      ]
      mountPoints = []
      volumesFrom = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${local.multiconainter-log-group}"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      systemControls = []
    },
    {
      name      = "backend"
      image     = "paripuranam/back-end"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      essential = true
      environment = [
        {
          name  = "PGHOST"
          value = "localhost"
        },
        {
          name  = "PGPORT"
          value = "5432"
        },
        {
          name  = "PGUSER"
          value = "postgres"
        },
        {
          name  = "PGDATABASE"
          value = "postgres"
        },
        {
          name  = "PGPASSWORD"
          value = "postgres_password"
        }
      ]
      mountPoints = []
      volumesFrom = []
      dependsOn = [
        {
          containerName = "postgresdb"
          condition     = "START"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${local.multiconainter-log-group}"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      systemControls = []
    },
    {
      name         = "postgresdb"
      image        = "postgres:latest"
      portMappings = []
      essential    = false
      environment = [
        {
          name  = "POSTGRES_PASSWORD"
          value = "postgres_password"
        }
      ]
      mountPoints = []
      volumesFrom = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${local.multiconainter-log-group}"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      systemControls = []
    }
  ])
  task_role_arn      = "arn:aws:iam::038146569014:role/ecsTaskExecutionRole"
  execution_role_arn = "arn:aws:iam::038146569014:role/ecsTaskExecutionRole"
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  cpu    = "1024"
  memory = "3072"
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "multi" {
  name            = "multicontainer-service-terraform"
  cluster         = aws_ecs_cluster.multi.id
  task_definition = aws_ecs_task_definition.multi.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = ["subnet-02e8c62b351c68ea4","subnet-07122e528fd9cd8ea","subnet-0747b58d31654f398"]
    assign_public_ip = true
  }
}

resource "aws_cloudwatch_log_group" "multicontainer-log-group" {
  name = "${local.multiconainter-log-group}"
}