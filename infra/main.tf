

# Variable para el nombre del clúster (la usaremos en varios lugares)
locals {
  cluster_name = "pulse-eks-cluster"
}

# 1. Crear la VPC de Alta Disponibilidad (exactamente como tu diagrama)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "pulse-vpc"
  cidr = "10.0.0.0/16"

  # Usamos dos zonas de disponibilidad para Alta Disponibilidad
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"] # Aquí irán los Pods
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"] # Aquí irá el Load Balancer

  enable_nat_gateway = true  # Necesario para que la App privada salga a internet
  single_nat_gateway = true  # Para ahorrar costos en el bootcamp
  
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Etiquetas requeridas por AWS para que el EKS sepa dónde poner los balanceadores
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "pulse-eks-cluster"
  cluster_version = "1.31" # Versión estable de Kubernetes

  # Acceso al clúster (público para que puedas usar kubectl desde tu PC)
  cluster_endpoint_public_access = true

  # Ubicación: Usamos las subredes PRIVADAS para los nodos (por seguridad)
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets

  # Configuración de los nodos (los servidores que trabajarán)
  eks_managed_node_groups = {
    pulse_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"] # Económico pero suficiente para pruebas
      capacity_type  = "SPOT"        # Ahorra hasta un 70% en costos de AWS
    }
  }

  # Configuración de acceso para que tú seas el administrador
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "dev"
    Project     = "pulse"
  }
}
resource "aws_budgets_budget" "pulse_budget" {
  name              = "presupuesto-mensual-pulse"
  budget_type       = "COST"
  limit_amount      = "7"          # <--- Cambia este número por tu límite en USD
  limit_unit        = "USD"
  time_period_start = "2026-02-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["blackwolf8591@gmail.com"] # <--- PON TU CORREO AQUÍ
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED" # Te avisa SI PREDICE que te pasarás
    subscriber_email_addresses = ["blackwolf8591@gmail.com"] # <--- PON TU CORREO AQUÍ
  }
}
# 1. Crear la política de IAM para el Load Balancer Controller
module "load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}