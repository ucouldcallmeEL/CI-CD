data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM role for SSM Session Manager - lets you reach the nodes for
# troubleshooting without opening SSH any wider than var.admin_cidr,
# and without distributing extra key material.
resource "aws_iam_role" "node" {
  name = "${var.project_name}-k8s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.project_name}-k8s-node-profile"
  role = aws_iam_role.node.name
}

resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_master
  subnet_id              = var.subnet_ids[0]
  key_name               = var.key_name
  vpc_security_group_ids = [var.master_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.node.name

  # Security hardening: force IMDSv2, no unauthenticated metadata access
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-k8s-master"
    Role = "master"
  }
}

resource "aws_instance" "worker" {
  count = var.worker_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_worker
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  key_name               = var.key_name
  vpc_security_group_ids = [var.worker_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.node.name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}
