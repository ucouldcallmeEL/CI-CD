# ---------------------------------------------------------------------------
# ALB security group - only this SG is exposed to the internet on the
# service ports; nothing else in the cluster is reachable directly from 0.0.0.0/0
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB - public entrypoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "To worker NodePort range"
    from_port   = var.node_port_range_start
    to_port     = var.node_port_range_end
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ---------------------------------------------------------------------------
# Master (control-plane) node security group
# ---------------------------------------------------------------------------
resource "aws_security_group" "master" {
  name        = "${var.project_name}-k8s-master-sg"
  description = "Kubernetes control-plane node"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from admin only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Kubernetes API server - reachable from within the VPC (workers, ansible
  # controller if it runs from a bastion/CI runner inside the VPC) and from
  # the admin CIDR for kubectl access.
  ingress {
    description = "Kubernetes API server (kube-apiserver)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.admin_cidr]
  }

  # etcd - cluster-internal only, kept for future control-plane HA even
  # though this design ships a single master
  ingress {
    description = "etcd client API"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # kubelet API on the master itself (kubeadm runs a kubelet on control-plane nodes too)
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "kube-scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "kube-controller-manager"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # CNI overlay (Flannel VXLAN default used by most kubeadm quick-starts).
  # Swap/extend this if the Ansible playbook installs Calico instead.
  ingress {
    description = "CNI overlay (flannel VXLAN)"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-k8s-master-sg"
    Role = "master"
  }
}

# ---------------------------------------------------------------------------
# Worker node security group
# ---------------------------------------------------------------------------
resource "aws_security_group" "worker" {
  name        = "${var.project_name}-k8s-worker-sg"
  description = "Kubernetes worker node"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from admin only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Kubelet API from master"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "CNI overlay (flannel VXLAN)"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NodePort services - only reachable from the ALB, never directly from the internet
  ingress {
    description     = "NodePort range from ALB"
    from_port       = var.node_port_range_start
    to_port         = var.node_port_range_end
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-k8s-worker-sg"
    Role = "worker"
  }
}
