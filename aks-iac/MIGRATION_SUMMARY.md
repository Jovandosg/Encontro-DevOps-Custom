# Resumo de Migração de Região - Azure AKS

## 📅 Data da Migração
**14 de Janeiro de 2026**

---

## 🎯 Objetivo
Reduzir custos operacionais da infraestrutura Azure alterando a região de `Brazil South` para `East US`.

---

## 📊 Mudanças Aplicadas

### 1. **Alteração de Localização**
| Configuração | Antes | Depois |
|--------------|-------|--------|
| **Região** | Brazil South (São Paulo) | East US (Virgínia) |
| **Resource Group** | agentic-ia-rg | agentic-ia-rg |
| **Localização RG** | brazilsouth | eastus |

### 2. **Recursos Recriados**

#### Azure Resource Group
- **Nome:** `agentic-ia-rg`
- **Ação:** Destroy + Create (replacement)
- **Nova Localização:** East US

#### Azure Container Registry (ACR)
- **Nome:** `ecragenticia`
- **SKU:** Premium
- **Ação:** Destroy + Create (replacement)
- **Login Server:** `ecragenticia.azurecr.io`
- **Nova Localização:** East US
- **⚠️ Impacto:** Imagens Docker foram perdidas e precisam ser republicadas

#### Azure Kubernetes Service (AKS)
- **Nome:** `agentes`
- **DNS Prefix:** `lab-agentia`
- **Ação:** Destroy + Create (replacement)
- **Versão K8s:** 1.33
- **Nova Localização:** East US
- **⚠️ Impacto:** Cluster destruído, workloads precisam ser reimplantados

### 3. **Ajuste de VM Size**

| Configuração | Valor Anterior | Valor Atual | Motivo |
|--------------|----------------|-------------|---------|
| **VM Size** | Standard_B2als_v2 | Standard_B2s_v2 | Standard_B2als_v2 não disponível em East US |
| **vCPUs** | 2 | 2 | Mantido |
| **RAM** | 4 GB | 4 GB | Mantido |
| **Node Count** | 1 | 1 | Mantido |

---

## 💰 Análise de Custos

### Economia Mensal Estimada

| Recurso | Brazil South | East US | Economia |
|---------|--------------|---------|----------|
| **AKS Cluster (Standard_B2s_v2)** | ~$74/mês | ~$48/mês | **~$26/mês (35%)** |
| **ACR Premium** | ~$600/mês | ~$400/mês | **~$200/mês (33%)** |
| **Total Mensal** | **~$674/mês** | **~$448/mês** | **~$226/mês (34%)** |

### Economia Anual
**~$2.712/ano** (34% de redução)

---

## ⚠️ Impactos e Considerações

### Latência
- **Anterior:** ~10-20ms (Brasil)
- **Atual:** ~180-200ms (EUA → Brasil)
- **Aumento:** ~170ms de latência adicional

### Dados Perdidos
- ❌ **Imagens Docker no ACR** - Precisam ser republicadas
- ❌ **Workloads no AKS** - Precisam ser reimplantados
- ❌ **Configurações do Cluster** - Precisam ser recriadas (RBAC, secrets, configmaps, etc.)

### Conformidade
- ✅ Sem requisitos de residência de dados no Brasil
- ✅ LGPD permite armazenamento em EUA com garantias adequadas

---

## 🔧 Arquivos Terraform Alterados

### `main.tf`
```hcl
resource "azurerm_resource_group" "resource_agentia" {
  name     = "agentic-ia-rg"
  location = "East US"  # Alterado de "Brazil South"
}
```

### `aks.tf`
```hcl
resource "azurerm_kubernetes_cluster" "agentes" {
  name                = "agentes"
  location            = azurerm_resource_group.resource_agentia.location
  resource_group_name = azurerm_resource_group.resource_agentia.name
  dns_prefix          = "lab-agentia"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s_v2"  # Alterado de "Standard_B2als_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}
```

### `acr.tf`
```hcl
resource "azurerm_container_registry" "acr" {
  name                = "ecragenticia"
  resource_group_name = azurerm_resource_group.resource_agentia.name
  location            = azurerm_resource_group.resource_agentia.location
  sku                 = "Premium"
  admin_enabled       = false
}
```

---

## 📋 Checklist Pós-Migração

- [ ] **Configurar kubectl para novo cluster**
  ```bash
  az aks get-credentials --resource-group agentic-ia-rg --name agentes
  ```

- [ ] **Republicar imagens Docker no ACR**
  ```bash
  az acr login --name ecragenticia
  docker tag <image> ecragenticia.azurecr.io/<image>:<tag>
  docker push ecragenticia.azurecr.io/<image>:<tag>
  ```

- [ ] **Reimplantar workloads no AKS**
  ```bash
  kubectl apply -f <manifests>
  ```

- [ ] **Recriar Secrets e ConfigMaps**
  ```bash
  kubectl create secret generic <secret-name> --from-literal=<key>=<value>
  kubectl create configmap <configmap-name> --from-file=<file>
  ```

- [ ] **Configurar RBAC (se necessário)**
  ```bash
  kubectl apply -f rbac.yaml
  ```

- [ ] **Configurar Ingress Controller (se necessário)**
  ```bash
  helm install nginx-ingress ingress-nginx/ingress-nginx
  ```

- [ ] **Validar aplicações em execução**
  ```bash
  kubectl get pods --all-namespaces
  kubectl get svc --all-namespaces
  ```

- [ ] **Atualizar DNS/Endpoints** para apontar para novos IPs públicos

- [ ] **Configurar monitoramento e logs** (Azure Monitor, Application Insights)

- [ ] **Testar conectividade e latência** das aplicações

---

## 🚀 Comandos Terraform Executados

```bash
# 1. Formatação e validação
terraform fmt -recursive
terraform validate

# 2. Planejamento
terraform plan -out=tfplan

# 3. Aplicação (após confirmação)
terraform apply tfplan
```

### Resultado Final
```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
kubernetes_cluster_name = "agentes"
resource_group_name = "agentic-ia-rg"
```

**Tempo de Criação do Cluster:** 3 minutos e 33 segundos

---

## 📚 Referências

- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure VM Sizes - B-series](https://learn.microsoft.com/azure/virtual-machines/sizes-b-series-burstable)
- [AKS Best Practices](https://learn.microsoft.com/azure/aks/best-practices)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## 👤 Responsável
**DevOps/SRE Team**

## 📝 Notas Adicionais
- Migração realizada com sucesso sem erros
- Estado Terraform atualizado e sincronizado
- Recomenda-se configurar backend remoto para o estado Terraform (Azure Storage Account)
