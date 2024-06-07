provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "fastapi_app" {
  name = "hsal25"
}

resource "aws_instance" "app" {
  count         = 2
  ami           = "ami-00975bcf7116d087c" # Use the appropriate AMI ID for your region
  instance_type = "t2.micro"
  key_name      = var.key_name

  tags = {
    Name = "fastapi-app-instance-${count.index + 1}"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "app" {
  name               = "fastapi-app-elb"
  availability_zones = ["us-west-2a", "us-west-2b"] # Update with your availability zones

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = aws_instance.app[*].id

  tags = {
    Name = "fastapi-app-elb"
  }
}

output "elb_dns_name" {
  value = aws_elb.app.dns_name
}