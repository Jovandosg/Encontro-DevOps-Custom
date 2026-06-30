# Manual de Deploy — Encontros DevOps

Guia completo passo a passo para provisionar a infraestrutura no Azure e colocar a aplicação em produção.

---

## Índice

1. [Pré-requisitos](#1-pré-requisitos)
2. [Clonar o Repositório](#2-clonar-o-repositório)
3. [Provisionar Infraestrutura (Terraform)](#3-provisionar-infraestrutura-terraform)
4. [Configurar GitHub Secrets e Variáveis](#4-configurar-github-secrets-e-variáveis)
5. [Executar o Pipeline CI/CD](#5-executar-o-pipeline-cicd)
6. [Verificar o Deploy](#6-verificar-o-deploy)
7. [Testar a Aplicação](#7-testar-a-aplicação)
8. [Execução Local (Docker)](#8-execução-local-docker)
9. [Arquitetura](#9-arquitetura)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Pré-requisitos

Instale e configure as ferramentas abaixo antes de iniciar:

| Ferramenta | Versão mínima | Instalação |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.5+ | `brew install terraform` / `choco install terraform` |
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | 2.60+ | `brew install azure-cli` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | 1.28+ | `az aks install-cli` |
| [Docker](https://docs.docker.com/get-docker/) | 24+ | Docker Desktop |
| [Git](https://git-scm.com/) | 2.40+ | incluído no SO |
| Conta [Docker Hub](https://hub.docker.com) | — | Gratuita |
| Conta [Azure](https://portal.azure.com) | — | Assinatura ativa |

```bash
# Verificar versões
terraform -version
az version
kubectl version --client
docker version
```

---

## 2. Clonar o Repositório

```bash
git clone https://github.com/Jovandosg/Encontro-DevOps-Custom.git
cd Encontro-DevOps-Custom
```

---

## 3. Provisionar Infraestrutura (Terraform)

### 3.1 Autenticar no Azure

```bash
az login
az account show  # confirme a assinatura correta
```

### 3.2 Configurar variáveis

```bash
cd aks-iac
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` com seus dados:

```hcl
subscription_id = "<seu-subscription-id>"
```

> **Dica:** para obter o subscription_id execute: `az account show --query id -o tsv`

### 3.3 Inicializar e aplicar

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

O Terraform criará automaticamente:
- Resource Group `rg-encontros-devops` (East US)
- VNet `vnet-encontro-devops` com subnet `snet-encontro-001` (251 hosts)
- AKS `aks-encontros-devops` (1 node Standard_B2s_v2)
- ACR `acrencontrosdevops`
- PostgreSQL 16 no AKS (namespace `postgres`) com databases:
  - `encontros_devops`
  - `prd-encontro-devops`
  - `hml-encontro-devops`

### 3.4 Salvar o kubeconfig

```bash
# O arquivo kubeconfig é gerado automaticamente pelo Terraform em aks-iac/kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes  # deve listar o node do AKS
```

---

## 4. Configurar GitHub Secrets e Variáveis

### 4.1 Criar environments no GitHub

Acesse **Settings → Environments** no repositório e crie:
- `homolog`
- `producao`

Ou via CLI:
```bash
gh api --method PUT repos/Jovandosg/Encontro-DevOps-Custom/environments/homolog --input - <<< '{}'
gh api --method PUT repos/Jovandosg/Encontro-DevOps-Custom/environments/producao --input - <<< '{}'
```

### 4.2 Configurar variáveis do repositório

```bash
gh variable set DOCKERHUB_USERNAME --body "<seu-usuario-dockerhub>" --repo Jovandosg/Encontro-DevOps-Custom
gh variable set ENABLE_DOCKER_PUSH --body "true" --repo Jovandosg/Encontro-DevOps-Custom
gh variable set ENABLE_CD --body "true" --repo Jovandosg/Encontro-DevOps-Custom
```

### 4.3 Configurar secrets do Docker Hub

Crie um **Personal Access Token** no Docker Hub:
1. Acesse [hub.docker.com → Account Settings → Personal Access Tokens](https://hub.docker.com/settings/personal-access-tokens)
2. Clique em **Generate new token**
3. Permissão: **Read & Write**
4. Copie o token gerado

```bash
gh secret set DOCKERHUB_TOKEN --repo Jovandosg/Encontro-DevOps-Custom
# Cole o token quando solicitado
```

### 4.4 Configurar secrets dos environments (kubeconfig e DATABASE_URL)

```bash
cd aks-iac

# KUBECONFIG — necessário para o CD conectar no AKS
gh secret set KUBECONFIG --repo Jovandosg/Encontro-DevOps-Custom --env homolog < kubeconfig
gh secret set KUBECONFIG --repo Jovandosg/Encontro-DevOps-Custom --env producao < kubeconfig

# DATABASE_URL — obtida do output do Terraform (URL-encoded automaticamente)
DB_URL=$(terraform output -raw postgres_database_url)
printf '%s' "$DB_URL" > /tmp/db_url.txt
gh secret set DATABASE_URL --repo Jovandosg/Encontro-DevOps-Custom --env homolog < /tmp/db_url.txt
gh secret set DATABASE_URL --repo Jovandosg/Encontro-DevOps-Custom --env producao < /tmp/db_url.txt
rm /tmp/db_url.txt
```

> **Atenção:** sempre use `printf '%s'` e redirecione para arquivo ao setar a `DATABASE_URL`. Nunca use `--body "$DB_URL"` pois o shell expande os `$` da senha.

---

## 5. Executar o Pipeline CI/CD

O pipeline é disparado automaticamente em qualquer **push na branch `main`**.

```
CI (build + push Docker Hub)
  └── CD-homolog (deploy namespace tech-homolog)
        └── CD-producao (deploy namespace tech-producao)
```

### Disparar manualmente

```bash
gh workflow run main.yml --repo Jovandosg/Encontro-DevOps-Custom
```

### Monitorar execução

```bash
# Listar últimas execuções
gh run list --repo Jovandosg/Encontro-DevOps-Custom --limit 5

# Acompanhar execução específica
gh run view <RUN_ID> --repo Jovandosg/Encontro-DevOps-Custom
```

---

## 6. Verificar o Deploy

```bash
export KUBECONFIG=aks-iac/kubeconfig

# Pods da aplicação
kubectl get pods -n tech-homolog
kubectl get pods -n tech-producao

# PostgreSQL
kubectl get pods -n postgres

# IP público do LoadBalancer
kubectl get svc encontros-devops -n tech-homolog
```

Saída esperada:
```
NAME                              READY   STATUS    RESTARTS   AGE
encontros-devops-xxx-yyy          1/1     Running   0          5m
encontros-devops-xxx-zzz          1/1     Running   0          5m
```

---

## 7. Testar a Aplicação

```bash
LB_IP=$(kubectl get svc encontros-devops -n tech-homolog \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Health check
curl http://$LB_IP/health
# Esperado: {"status":"healthy","version":"1.0.0"}

# Homepage
curl -o /dev/null -w "%{http_code}" http://$LB_IP/
# Esperado: 200

# API de eventos
curl http://$LB_IP/api/events/
# Esperado: 200 com lista de eventos
```

Ou acesse diretamente no browser: `http://<LB_IP>`

---

## 8. Execução Local (Docker)

```bash
# Com Docker Compose (inclui PostgreSQL local)
docker compose up -d
# Acesse: http://localhost:8000

# Ou com imagem do Docker Hub
docker run -d \
  --name encontros-devops \
  -p 8000:8000 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  jovandosg/encontros-devops:latest
```

---

## 9. Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Actions CI/CD                  │
│  push → main                                            │
│    CI: pytest → docker build → docker push (Docker Hub) │
│    CD-homolog: kubectl deploy → namespace tech-homolog  │
│    CD-producao: kubectl deploy → namespace tech-producao│
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│               Azure (East US)                           │
│  Resource Group: rg-encontros-devops                    │
│                                                         │
│  VNet: vnet-encontro-devops (10.0.0.0/16)               │
│    └── Subnet: snet-encontro-001 (10.0.1.0/24)         │
│                                                         │
│  AKS: aks-encontros-devops                              │
│    ├── namespace: postgres                              │
│    │     └── PostgreSQL 16 (PVC 10Gi)                  │
│    │           ├── DB: encontros_devops                 │
│    │           ├── DB: prd-encontro-devops              │
│    │           └── DB: hml-encontro-devops              │
│    ├── namespace: tech-homolog                          │
│    │     └── encontros-devops (2 réplicas)              │
│    │           └── LoadBalancer → 80                   │
│    └── namespace: tech-producao                         │
│          └── encontros-devops (2 réplicas)              │
│                └── LoadBalancer → 80                   │
│                                                         │
│  ACR: acrencontrosdevops                                │
└─────────────────────────────────────────────────────────┘
```

---

## 10. Troubleshooting

### Pod em CrashLoopBackOff
```bash
# Ver logs do pod
kubectl logs <pod-name> -n tech-homolog --previous

# Causas comuns:
# - DATABASE_URL incorreta (verificar se a senha está URL-encoded)
# - PostgreSQL ainda não está pronto (aguardar ~30s)
```

### Pod em Pending (Insufficient CPU)
```bash
# Ver motivo
kubectl describe pod <pod-name> -n tech-homolog | grep -A5 Events

# Solução: reduzir requests no k8s/manifests.yaml
# requests.cpu: 100m  ← valor atual, adequado para single node
```

### DATABASE_URL com senha corrompida
```bash
# Extrair e reconfigurar corretamente
cd aks-iac
PGPASSWORD=$(terraform show -json | python3 -c "
import sys, json
state = json.load(sys.stdin)
for r in state['values']['root_module']['resources']:
    if r['type'] == 'random_password':
        print(r['values']['result']); break
")
ENCODED=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$PGPASSWORD")
printf "postgresql://psqladmin:%s@postgres.postgres.svc.cluster.local:5432/encontros_devops" "$ENCODED" > /tmp/db_url.txt
gh secret set DATABASE_URL --repo Jovandosg/Encontro-DevOps-Custom --env homolog < /tmp/db_url.txt
kubectl create secret generic encontros-devops-secrets \
  --from-literal=DATABASE_URL=$(cat /tmp/db_url.txt) \
  --namespace=tech-homolog --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/encontros-devops -n tech-homolog
rm /tmp/db_url.txt
```

### Pipeline CI falhou no Login Docker Hub
- Verificar se `DOCKERHUB_TOKEN` tem permissão **Read & Write**
- Verificar se `DOCKERHUB_USERNAME` está correto em **Settings → Variables**

### Terraform: LocationIsOfferRestricted (PostgreSQL)
- Assinatura Visual Studio tem restrições para PostgreSQL Flexible Server
- Solução implementada: PostgreSQL rodando dentro do AKS como container

---

> **Repositório:** https://github.com/Jovandosg/Encontro-DevOps-Custom  
> **Imagem Docker:** `jovandosg/encontros-devops:latest`  
> **Aplicação em produção:** http://172.214.120.160
