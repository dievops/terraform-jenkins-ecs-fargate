# S3 bucket for terraform states.
# DynamoDB table for lock.

variable "region" {
  type = string
}

variable "project" {
    type = string
}

variable "environment" {
    type = string
}

variable "additional_tags" {
  type        = map(string)
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "terraform_state_backend" {
  bucket = format("%s-%s-%s","terraform-state-backend",var.project,var.environment)
  acl    = "private"
  force_destroy = true

  # To allow rolling back states
  versioning {
    enabled = true
  }

  # To cleanup old states eventually
  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 90
    }
  }

  tags = merge(
    var.additional_tags,
    {
      Name = format("%s-%s-%s","terraform-state-backend",var.project,var.environment)
    })
}

resource "aws_dynamodb_table" "terraform_lock_state" {
  name           = format("%s-%s-%s","terraform-lock-state",var.project,var.environment)
  # up to 25 per account is free
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.additional_tags,
    {
      Name = format("%s-%s-%s","terraform-lock-state",var.project,var.environment)
    })
}