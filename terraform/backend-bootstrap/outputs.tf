output "TF_VAR_s3_bucket" {
  value = format(aws_s3_bucket.terraform_state_backend.id)
}

output "TF_VAR_dynamo_db_table" {
  value = format(aws_dynamodb_table.terraform_lock_state.id)
}