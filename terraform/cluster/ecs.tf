resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = format("%s-%s",var.project, var.environment)
  tags = {
    Name        = format("%s-%s",var.project, var.environment)
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = format("%s-%s-%s",var.project, var.environment,"logs")

  tags = {
    Project = var.project
    Environment = var.environment
  }
}

##env vars for container.
data "template_file" "env_vars" {
  template = file("${path.module}/json/env_vars.json")
}

data "template_file" "jenkins_container_definition" {
    template = file("${path.module}/json/jenkins.tpl")
    vars = {
        name = format("%s-%s-%s",var.project, var.environment, "container")
        image = var.container_image
        project = var.project
        environment = var.environment
        region = var.region
        memoryReservation = var.container_memory
    }
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = format("%s-%s-%s",var.project, var.environment,"task")
  container_definitions = data.template_file.jenkins_container_definition.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = var.container_memory
  cpu                      = var.container_cpu
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  volume {
    name  = "jenkins-home"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs.id
      root_directory = "/"
    }
  }

  tags = {
    Name        = format("%s-%s-%s",var.project, var.environment,"task")
    Environment = var.environment
  }
}

#data "aws_ecs_task_definition" "main" {
#  task_definition = aws_ecs_task_definition.aws-ecs-task.family
#}

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = format("%s-%s-%s",var.project, var.environment,"ecs-service")
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = aws_ecs_task_definition.aws-ecs-task.arn
  launch_type          = "FARGATE"
  platform_version = "1.4.0"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = true
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id,
      aws_security_group.jenkins-sg.id
    ]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.jenkins.arn
    container_name   = format("%s-%s-%s",var.project, var.environment,"container")
    container_port   = 8080
  }

  depends_on = [aws_alb_listener.front_end,aws_alb_target_group.jenkins]
}

resource "aws_security_group" "service_security_group" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = format("%s-%s-%s",var.project, var.environment,"sg")
    Environment = var.environment
  }
}

resource "aws_security_group" "jenkins-sg" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "tcp"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name        = format("%s-%s-%s",var.project, var.environment,"container-sg")
    Environment = var.environment
  }
}