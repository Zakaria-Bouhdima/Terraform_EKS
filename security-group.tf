# ── Control Plane Security Group ───────────────────────────────────────────────

resource "aws_security_group" "eks_cluster" {
  name        = "${var.eks_cluster_name}-${var.env}/ControlPlaneSecurityGroup"
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.eks_cluster_name}-${var.env}/ControlPlaneSecurityGroup"
    Environment = var.env
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the control plane"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  type                     = "ingress"
  security_group_id        = aws_eks_cluster.myeks.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.eks_nodes_sec.id
}

# ── Node Shared Security Group ─────────────────────────────────────────────────

resource "aws_security_group" "eks_nodes_sec" {
  name        = "${var.eks_cluster_name}-${var.env}/ClusterSharedNodeSecurityGroup"
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.myeks.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.eks_cluster_name}-${var.env}/ClusterSharedNodeSecurityGroup"
    Environment = var.env
  }
}
