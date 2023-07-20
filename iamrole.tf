resource "aws_iam_role" "SSMRoleforEC2" {
  name = "SSMRoleforEC2_1"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "1"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "SSMRoleforEC2_1"
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEC2RoleforSSM" {
  role       = aws_iam_role.SSMRoleforEC2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
resource "aws_iam_role_policy_attachment" "AmazonSSMFullAccess" {
  role       = aws_iam_role.SSMRoleforEC2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMAutomationRole" {
  role       = aws_iam_role.SSMRoleforEC2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

resource "aws_iam_instance_profile" "SSMRoleforEC2_profile" {
  name = "SSMRoleforEC2_profile"
  role = aws_iam_role.SSMRoleforEC2.name
}