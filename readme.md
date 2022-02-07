# Usage

## Create an s3 bucket and dynamodb table for store state and lock.

RUN:

./ecs.py backend_bootstrap

## Deploy ecs cluster using backend from backend_bootstrap.

RUN:

./ecs.py jenkins_deploy


## Destroy the s3 buckets and dynamo + ecs cluster + clean files.

RUN:

./ecs.py destroy

# Jenkins image.

Use the dockerfile from this project to build your jenkins image because the official image cause permissions issues with fargate/ecs.

:)