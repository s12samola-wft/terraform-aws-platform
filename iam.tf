# Trust policy: ONLY EC2 servers may wear this badge
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The badge itself (IAM role), with the trust policy attached
resource "aws_iam_role" "web" {
  name               = "web-server-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Permission policy: the doors the badge opens (Session Manager only)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# The badge holder that clips the role onto a server
resource "aws_iam_instance_profile" "web" {
  name = "web-server-profile"
  role = aws_iam_role.web.name
}