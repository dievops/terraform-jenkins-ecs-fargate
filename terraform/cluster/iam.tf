resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = format("%s-%s-%s", var.project,var.environment,"execution-task-role")
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name        = format("%s-%s-%s", var.project,var.environment,"iam-role")
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}