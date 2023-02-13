resource "aws_default_vpc" "default" {
    tags = {
        Name = "Default VPC"
    }
}

data "aws_availability_zones"  "available" {

}

resource "aws_default_subnet" "default_azl" {
    availability_zone = data.aws_availability_zones.available.names[0]

    tags = {
        Name = "Default subnet for ap-southeast-1a"

    }
}

resource "aws_security_group" "my_sg" {
    name              =   "allow_tls_gr"
    description       =   "Allow 8080 22 inbound traffic"
    vpc_id            =   aws_default_vpc.default.id

    ingress {
        from_port     =   22
        to_port       =   22
        description   =   "SSH Access"
        protocol      =   "tcp"
        cidr_blocks   =   ["0.0.0.0/0"]
    }

    ingress {
        from_port     =   8080
        to_port       =   8080
        description   =   "HTTP access"
        protocol      =   "tcp"
        cidr_blocks   =   ["0.0.0.0/0"]
    }

    egress {
        from_port         =  0
        to_port           =  0
        description       =  "TLS outbound open"
        protocol          =  "-1"
        cidr_blocks       =  ["0.0.0.0/0"]
        ipv6_cidr_blocks  =  ["::/0"]
    }

    tags = {
        Name = "Allow TLS"
    }
}

resource "aws_instance" "jenkins_ec2"{
    ami = "ami-082b1f4237bd816a1"
    instance_type = "t2.micro"
    subnet_id = aws_default_subnet.default_azl.id
    vpc_security_group_ids = [aws_security_group.my_sg.id]
    key_name        = "ec2-key"

    tags = {
        Name = "Jenkins"
    }
}

resource "null_resource" "name" {

    # SSH into ec2 instance
    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file("D:\\Software\\Putty\\ec2-key.pem")
        host = aws_instance.jenkins_ec2.public_ip
    }

    # Copy jenkins.sh from local to ec2 instance
    provisioner "file" {
      source = "jenkins.sh"
      destination = "/tmp/jenkins.sh"
    }

    # Set permission and execute the install_jenkins.sh file
    provisioner "remote-exec" {
        inline = [
                "sudo chmod +x /tmp/jenkins.sh",
                "sh /tmp/jenkins.sh"
        ]
    }

    depends_on = [
      aws_instance.jenkins_ec2
    ]
}