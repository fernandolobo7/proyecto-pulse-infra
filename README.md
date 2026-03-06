# 🚀 Proyecto PULSE - Infraestructura EKS y Observabilidad

Sistema de microservicios basado en Python, desplegado en Amazon EKS mediante Infraestructura como Código (Terraform) y monitoreado con Prometheus/Grafana.

---

## 🏗️ Arquitectura Completa
Este proyecto implementa una infraestructura robusta y escalable en AWS:
- **Infraestructura (IaC):** VPC personalizada, subredes públicas/privadas, NAT Gateway y clúster EKS gestionado vía **Terraform**.
- **Orquestación:** Gestión de cargas de trabajo y autoescalado (HPA) mediante **Kubernetes**.
- **Monitoreo:** Stack completo de **Prometheus y Grafana** para la recolección de métricas de rendimiento.
- **Aplicación:** Microservicio en **Python (Flask)** contenido en Docker.



---

## 🛠️ Guía de Ejecución Paso a Paso

### 1. Preparación de Infraestructura (Terraform)
Provisionamiento de todos los recursos necesarios en AWS:
```bash
# Entrar al directorio de infraestructura
cd infra

# Inicializar y aplicar cambios
terraform init
terraform apply -auto-approve

# Actualizar las credenciales de acceso al clúster
aws eks update-kubeconfig --name pulse-eks-cluster --region us-east-1

# Desplegar aplicación, servicios y HPA
kubectl apply -f k8s/

# Verificar que los pods estén corriendo
kubectl get pods -n default

# Redirección de puerto para acceder a Grafana (localhost:3000)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80