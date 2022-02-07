resource "aws_alb_target_group" "jenkins" {
  name     = format("%s-%s",var.project,var.environment)
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "ip"

    health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/login"
    unhealthy_threshold = "2"
    port = "8080"
  }

  tags = {
    Name        = format("%s-%s-%s",var.project, var.environment,"tg")
    Environment = var.environment
  }
}

resource "aws_alb" "jenkins" {
  name            = format("%s-%s",var.project,var.environment)
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.load_balancer_security_group.id]
}

resource "aws_alb_listener" "front_end" {
  depends_on = [aws_alb_target_group.jenkins]
  load_balancer_arn = aws_alb.jenkins.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.jenkins.id
    type             = "forward"
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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