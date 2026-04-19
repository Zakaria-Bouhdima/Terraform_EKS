output "eks_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.myeks.endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.myeks.name
}

output "kubeconfig_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for kubeconfig"
  value       = aws_eks_cluster.myeks.certificate_authority[0].data
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC created for the cluster"
  value       = aws_vpc.main.id
}
