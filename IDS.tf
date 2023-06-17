# Define provider and region
provider "aws" {
  region = "us-east-1"
}

# Define VPC
resource "aws_vpc" "ids_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Define subnet
resource "aws_subnet" "ids_subnet" {
  vpc_id     = aws_vpc.ids_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Define network load balancer
resource "aws_lb_network_interface" "ids_lb_interface" {
  subnet_id = aws_subnet.ids_subnet.id
}

resource "aws_lb" "ids_lb" {
  name               = "ids-lb"
  internal           = true
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id = aws_subnet.ids_subnet.id
  }

  depends_on = [aws_lb_network_interface.ids_lb_interface]
}

# Define Amazon GuardDuty detector
resource "aws_guardduty_detector" "ids_detector" {
  enable = true
}

# Configure load balancer to direct traffic to detector
resource "aws_lb_target_group" "ids_target_group" {
  name_prefix      = "ids-target-group"
  port             = 80
  protocol         = "TCP"
  vpc_id           = aws_vpc.ids_vpc.id
  target_type      = "instance"
  health_check {
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "ids_listener" {
  load_balancer_arn = aws_lb.ids_lb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ids_target_group.arn
  }
}

# Test IDS solution by creating a simulated security event
resource "aws_instance" "test_instance" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ids_subnet.id

  user_data = <<-EOF
              #!/bin/bash
              curl http://169.254.169.254/latest/meta-data/instance-id > /tmp/instance-id
              EOF
}

# Destroy load balancer and detector
resource "aws_lb" "ids_lb_destroy" {
  name = aws_lb.ids_lb.name
  arn  = aws_lb.ids_lb.arn

  lifecycle {
    ignore_changes = [subnet_mapping]
  }
  depends_on = [aws_lb_listener.ids_listener]
}

resource "aws_guardduty_detector" "ids_detector_destroy" {
  detector_id = aws_guardduty_detector.ids_detector.detector_id
  depends_on  = [aws_lb_target_group.ids_target_group]
}s