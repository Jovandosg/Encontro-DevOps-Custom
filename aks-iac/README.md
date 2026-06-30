# AKS IaC (Terraform)

Infraestrutura Azure completa para a aplicação Encontros DevOps.

## Recursos provisionados

| Recurso | Nome | Descrição |
|---|---|---|
| Resource Group | `rg-encontros-devops` | Contêiner de todos os recursos (East US) |
| VNet | `vnet-encontro-devops` | Rede virtual `10.0.0.0/16` |
| Subnet | `snet-encontro-001` | Sub-rede `10.0.1.0/24` (251 hosts) |
| AKS | `aks-encontros-devops` | Kubernetes 1.35 — 1 node Standard_B2s_v2 |
| ACR | `acrencontrosdevops` | Container Registry para imagens |
| PostgreSQL | pod `postgres` (AKS) | PostgreSQL 16 com PVC 10Gi |

## Estrutura dos arquivos

```
aks-iac/
├── main.tf              # Providers (azurerm, kubernetes, random) e Resource Group
├── aks.tf               # Cluster AKS
├── acr.tf               # Azure Container Registry
├── postgres.tf          # Senha aleatória para o PostgreSQL
├── postgres-k8s.tf      # PostgreSQL no AKS (Namespace, Secret, PVC, Deployment, Service)
├── variables.tf         # Variáveis de entrada
├── outputs.tf           # Outputs (kubeconfig, postgres_host, DATABASE_URL)
├── terraform.tfvars.example  # Template de variáveis
├── terraform.tfvars     # Suas variáveis (ignorado pelo git)
└── modules/
    └── vnet/
        ├── main.tf      # VNet e Subnet
        ├── variables.tf # Variáveis do módulo
        └── outputs.tf   # IDs da VNet e Subnet
```

## Como usar

```bash
cd aks-iac

# 1. Configurar variáveis
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars com seu subscription_id:
# subscription_id = "<seu-subscription-id>"

# 2. Inicializar
terraform init

# 3. Validar
terraform fmt -recursive
terraform validate

# 4. Planejar
terraform plan -out=tfplan

# 5. Aplicar
terraform apply tfplan
```

## Outputs disponíveis

```bash
terraform output kubernetes_cluster_name   # Nome do cluster AKS
terraform output resource_group_name       # Nome do Resource Group
terraform output postgres_host             # DNS interno do PostgreSQL
terraform output postgres_database_url     # DATABASE_URL completa (sensitive)
```

## Módulo VNet

O módulo `modules/vnet` cria a rede virtual com:
- **VNet:** `vnet-encontro-devops` — CIDR `10.0.0.0/16`
- **Subnet:** `snet-encontro-001` — CIDR `10.0.1.0/24` → **251 hosts disponíveis**
  (Azure reserva 5 endereços por subnet: rede, broadcast e 3 internos)

## Nota sobre PostgreSQL

O Azure PostgreSQL Flexible Server está bloqueado em assinaturas Visual Studio.
A solução implementada usa **PostgreSQL 16 dentro do AKS** (namespace `postgres`):
- Conectividade via DNS interno: `postgres.postgres.svc.cluster.local:5432`
- Três databases criados via init SQL: `encontros_devops`, `prd-encontro-devops`, `hml-encontro-devops`
- Dados persistidos em PVC de 10Gi

Para assinaturas sem restrição, substitua o conteúdo de `postgres.tf` pelo
recurso `azurerm_postgresql_flexible_server` e remova `postgres-k8s.tf`.
