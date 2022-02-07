### EFS ###

resource "aws_efs_file_system" "efs" {
  creation_token = format("%s-%s",var.project,var.environment)
  performance_mode = "generalPurpose"
  encrypted = true  
  tags = merge(var.additional_tags,
  {
    Name = format("%s-%s",var.project,var.environment)
  },
  )

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
}

resource "aws_efs_mount_target" "mount_target" {
  depends_on = [aws_security_group.efs]
  count = length(module.vpc.private_subnets)
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  depends_on = [aws_efs_file_system.efs, module.vpc]
  name        = format("%s-%s-%s","efs",var.project,var.environment)
  description = format("%s-%s-%s","efs",var.project,var.environment)
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.additional_tags,
  {
    Name = format("%s-%s-%s","efs",var.project,var.environment)
  },
  )
}