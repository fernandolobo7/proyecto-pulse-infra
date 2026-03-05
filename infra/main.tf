# Variable para el nombre del clúster
locals {
  cluster_name = "pulse-eks-cluster"
}

# 1. Crear la VPC de Alta Disponibilidad
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "pulse-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"] 
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

# 2. Configurar el Clúster EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # CONFIGURACIÓN DE NODOS (CORREGIDA)
  eks_managed_node_groups = {
    pulse_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      # --- CAMBIO CLAVE AQUÍ ---
      # Eliminamos el bloque 'remote_access' y usamos 'key_name'.
      # Esto inyecta la llave SSH directamente en la Launch Template.
      key_name = "pulse-key"
      
      # Opcional: habilitamos el acceso remoto en el security group de los nodos
      enable_remote_access = true
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "dev"
    Project     = "pulse"
  }
}

# 3. Presupuesto de AWS
resource "aws_budgets_budget" "pulse_budget" {
  name              = "presupuesto-mensual-pulse"
  budget_type       = "COST"
  limit_amount      = "7"
  limit_unit        = "USD"
  time_period_start = "2026-02-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["blackwolf8591@gmail.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["blackwolf8591@gmail.com"]
  }
}