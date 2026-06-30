# DevOps Engineering Standards

## Objetivo

Este projeto segue práticas DevOps, Cloud Engineering e FinOps.

Tecnologias principais:

- Azure
- Terraform
- GitHub Actions
- Kubernetes (AKS)
- Azure OpenAI
- Azure Functions
- Azure Storage
- Azure Key Vault

---

# Infraestrutura

## Infrastructure as Code

Toda infraestrutura deve ser criada utilizando Terraform.

Evitar:

- Criação manual no Portal Azure
- Configurações não rastreadas em código

Priorizar:

- Módulos reutilizáveis
- Estrutura modular
- Versionamento Git

---

# Terraform

Sempre executar:

- terraform fmt
- terraform validate

Sempre utilizar:

- variables.tf
- outputs.tf
- terraform.tfvars

Evitar valores hardcoded.

Utilizar nomes descritivos.

Adicionar comentários apenas quando necessário.

---

# Azure

## Segurança

Priorizar:

- Managed Identity
- RBAC
- Private Endpoints
- Network Security

Evitar:

- Access Keys
- Segredos em código
- Recursos públicos desnecessários

---

## Tags obrigatórias

Todos os recursos devem possuir:

- Environment
- Application
- Owner
- CostCenter
- ManagedBy

---

# Kubernetes (AKS)

Todo Deployment deve possuir:

- requests
- limits
- livenessProbe
- readinessProbe

Nunca utilizar:

- latest
- containers privilegiados
- execução como root

---

# GitHub Actions

Todo pipeline deve possuir:

1. Lint
2. Testes
3. Security Scan
4. Build
5. Deploy

Priorizar autenticação via:

- OIDC
- Federated Credentials

Evitar Client Secret.

---

# FinOps

Ao analisar infraestrutura Azure:

Identificar:

- recursos ociosos
- discos não anexados
- public IPs não utilizados
- storage accounts sem uso
- clusters AKS superdimensionados

Sempre sugerir otimizações de custo.

---

# Observabilidade

Priorizar:

- Azure Monitor
- Log Analytics
- Application Insights

Aplicações devem expor:

- health endpoint
- métricas
- logs estruturados

---

# Respostas do Copilot

Sempre responder utilizando:

1. Análise
2. Solução
3. Implementação
4. Validação
5. Impacto em Segurança
6. Impacto em Custos

Sempre explicar decisões arquiteturais.