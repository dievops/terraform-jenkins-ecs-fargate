[
    {
      "name": "${name}",
      "image": "${image}",
      "cpu": 0,
      "memoryReservation": 1024,
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${project}-${environment}",
          "awslogs-region": "${region}",
          "awslogs-stream-prefix": "${project}"
        }
      },
      "portMappings": [
        {
          "containerPort" : 8080,
          "hostPort" : 8080
        }
      ],
      "mountPoints": [
        {
            "sourceVolume" : "jenkins-home",
            "containerPath" : "/var/jenkins_home",
            "readOnly": false
        }
        ]
    }
  ]