# ── KMS Key for EKS Secret Encryption ─────────────────────────────────────────

resource "aws_kms_key" "eks" {
  description             = "EKS secrets encryption key for ${var.eks_cluster_name}-${var.env}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Environment = var.env }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.eks_cluster_name}-${var.env}"
  target_key_id = aws_kms_key.eks.key_id
}

# ── EKS Cluster ────────────────────────────────────────────────────────────────

resource "aws_eks_cluster" "myeks" {
  name     = "${var.eks_cluster_name}-${var.env}"
  role_arn = aws_iam_role.eks.arn
  version  = "1.33"

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true #trivy:ignore:aws-eks-no-public-cluster-access
    public_access_cidrs     = [var.internal_ip_range]
    subnet_ids = [
      aws_subnet.private["private-1"].id,
      aws_subnet.private["private-2"].id,
      aws_subnet.public["public-1"].id,
      aws_subnet.public["public-2"].id,
    ]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]

  tags = { Environment = var.env }
}

# ── Node Groups ────────────────────────────────────────────────────────────────

resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.myeks.name
  node_group_name = "private-node-group-${var.env}"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = [aws_subnet.private["private-1"].id, aws_subnet.private["private-2"].id]

  labels = { type = "private" }

  instance_types = ["t3.small"]
  disk_size      = 25

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = { Environment = var.env }
}

resource "aws_eks_node_group" "public" {
  cluster_name    = aws_eks_cluster.myeks.name
  node_group_name = "public-node-group-${var.env}"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = [aws_subnet.public["public-1"].id, aws_subnet.public["public-2"].id]

  labels = { type = "public" }

  instance_types = ["t3.small"]
  disk_size      = 25

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = { Environment = var.env }
}
