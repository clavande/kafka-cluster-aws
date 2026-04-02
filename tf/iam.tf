# --- IAM ROLE FOR BROKERS ---
resource "aws_iam_role" "broker" {
  name = "${var.project_name}-broker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.broker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.broker.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "broker" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.broker.name
}

output "instance_profile" {
  value = aws_iam_instance_profile.broker.name
}
