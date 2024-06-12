provider "aws" {
  region = var.aws_region
}

# Check if the ECR repository already exists
data "aws_ecr_repository" "existing_repo" {
  name = "hsal25"
}

# Create the ECR repository if it does not exist
resource "aws_ecr_repository" "fastapi_app" {
  count = length(data.aws_ecr_repository.existing_repo.id) == 0 ? 1 : 0
  name  = "hsal25"
}

# Use the existing ECR repository if it exists
locals {
  ecr_repo_name = length(data.aws_ecr_repository.existing_repo.id) > 0 ? data.aws_ecr_repository.existing_repo.name : aws_ecr_repository.fastapi_app[0].name
}

resource "aws_instance" "app" {
  count         = 2
  ami           = "ami-00975bcf7116d087c" # Provided AMI ID for eu-central-1
  instance_type = "t2.micro"
  key_name      = var.key_name

  associate_public_ip_address = true

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

# Check if the ELB already exists
data "aws_elb" "existing_elb" {
  name = "fastapi-app-elb"
}

# Create the ELB if it does not exist
resource "aws_elb" "app" {
  count              = length(data.aws_elb.existing_elb.name) == 0 ? 1 : 0
  name               = "fastapi-app-elb"
  availability_zones = ["eu-central-1a", "eu-central-1b"] # Update with your availability zones

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
  value = length(data.aws_elb.existing_elb.name) > 0 ? data.aws_elb.existing_elb.dns_name : aws_elb.app[0].dns_name
}

output "instances" {
  value = aws_instance.app[*].public_ip
}