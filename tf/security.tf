resource "aws_security_group" "kafka" {
  name        = "${var.project_name}-sg"
  description = "Enable Kafka and SSH access"
  vpc_id      = aws_vpc.main.id

  # Kafka Clients (Within VPC)
  ingress {
    from_port   = 9092
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kafka Inter-Broker & Client traffic"
  }

  # SSH Access (For Bastion and Management)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH Access"
  }

  # Allow all outbound (To reach NAT/Mirror)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

output "security_group_id" {
  value = aws_security_group.kafka.id
}
