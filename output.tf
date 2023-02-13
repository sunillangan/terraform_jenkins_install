output "jenkins_url" {
    value = join("", ["http://", aws_instance.jenkins_ec2.public_dns, ":", "8080"])
}