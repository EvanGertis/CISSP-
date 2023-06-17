resource "aws_security_group" "example" {
  name        = "example"
  description = "Example security group"
}

resource "aws_security_group_rule" "example" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}