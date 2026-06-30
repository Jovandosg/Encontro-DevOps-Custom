# AKS IaC (Terraform)

Infraestrutura Azure para a aplicação Encontros DevOps:

- Resource Group
- AKS
- ACR

## Arquivos

- `main.tf`: provider e resource group
- `aks.tf`: cluster AKS
- `acr.tf`: container registry (ACR)
- `variables.tf`: variáveis de entrada
- `outputs.tf`: outputs do provisionamento

## Como usar

```bash
cd aks-iac
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars com seu subscription_id

terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```
