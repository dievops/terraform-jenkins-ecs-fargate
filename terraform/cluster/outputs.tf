output "jenkins-endpoint" {
    value = aws_alb.jenkins.dns_name
}