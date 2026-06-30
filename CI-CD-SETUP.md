# CI/CD Setup Guide

Este guia descreve como configurar e utilizar o pipeline de CI/CD para automatizar o deploy da aplicação **Encontros DevOps**.

## 📋 Visão Geral

O pipeline automatiza:

1. **CI (Integração Contínua)**
   - Instalação de dependências
   - Execução de testes
   - Build da imagem Docker
   - Push para Docker Hub

2. **CD (Entrega Contínua)**
   - Deploy automático para ambiente de **Homologação** (tech-homolog)
   - Deploy automático para ambiente de **Produção** (tech-producao) após aprovação

## 🔧 Pré-requisitos

### 1. Conta Docker Hub

Crie uma conta em [hub.docker.com](https://hub.docker.com) e gere um **Access Token**:

1. Acesse: Settings → Security → New Access Token
2. Nome: `github-actions`
3. Permissions: **Read, Write, Delete**
4. Copie o token gerado (você não verá novamente!)

### 2. Cluster Kubernetes

Você precisará de um cluster Kubernetes (Azure AKS, AWS EKS, GKE, etc.) e do arquivo `kubeconfig` configurado.

Para Azure AKS:
```bash
az aks get-credentials --resource-group <rg-name> --name <cluster-name>
cat ~/.kube/config
```

### 3. Banco de Dados PostgreSQL

Configure um banco PostgreSQL acessível pelo cluster e obtenha a URL de conexão:
```
postgresql://usuario:senha@host:5432/database
```

## ⚙️ Configuração no GitHub

### Variables (Settings → Secrets and variables → Actions → Variables)

Crie as seguintes **Variables**:

| Nome | Valor | Descrição |
|------|-------|-----------|
| `ENABLE_DOCKER_PUSH` | `true` | Habilita push de imagem Docker |
| `ENABLE_CD` | `true` | Habilita deploy automático |
| `DOCKERHUB_USERNAME` | `seu-usuario` | Seu usuário do Docker Hub |

### Secrets (Settings → Secrets and variables → Actions → Secrets)

Crie os seguintes **Secrets**:

| Nome | Valor | Descrição |
|------|-------|-----------|
| `DOCKERHUB_TOKEN` | `dckr_pat_xxxxx` | Token de acesso do Docker Hub |
| `KUBECONFIG` | `conteúdo do ~/.kube/config` | Configuração do cluster Kubernetes |
| `DATABASE_URL` | `postgresql://...` | URL de conexão do PostgreSQL |

### Environments (Settings → Environments)

Crie dois ambientes para controle de aprovação:

#### 1. homolog
- **Deployment branches**: Selected branches → `main`
- **Protection rules**: Nenhuma (deploy automático)

#### 2. producao
- **Deployment branches**: Selected branches → `main`
- **Protection rules**: 
  - ✅ **Required reviewers**: Adicione revisores (pelo menos 1)
  - ⏱️ **Wait timer**: 0 minutos (ou configure um delay)

## 🚀 Como Funciona

### Fluxo Completo

```mermaid
graph LR
    A[Push/PR para main] --> B[CI: Testes]
    B --> C{Passou?}
    C -->|Sim| D[Build Docker Image]
    D --> E[Push para Docker Hub]
    E --> F[Deploy Homolog]
    F --> G{Aprovação Manual}
    G -->|Aprovado| H[Deploy Produção]
    G -->|Rejeitado| I[Fim]
    C -->|Não| I
```

### 1. Pull Request

Quando você abre um PR para `main`:
- ✅ Roda testes automaticamente
- ✅ Valida o código
- ❌ **NÃO** faz build/deploy

### 2. Push para Main (Merge)

Quando você faz merge para `main`:
1. **CI Job**:
   - Instala dependências
   - Roda testes
   - Faz build da imagem Docker
   - Faz push com tags:
     - `latest`
     - `v{run_number}` (ex: v42)

2. **CD-homolog Job**:
   - Cria namespace `tech-homolog` (se não existir)
   - Cria secret com `DATABASE_URL`
   - Faz deploy da aplicação
   - **Deploy automático** (sem aprovação)

3. **CD-producao Job**:
   - **Aguarda aprovação manual** (se configurado)
   - Cria namespace `tech-producao`
   - Cria secret com `DATABASE_URL`
   - Faz deploy da aplicação

### 3. Manual Workflow

Você pode disparar o pipeline manualmente:
1. Vá em **Actions** → **CI/CD Pipeline**
2. Clique em **Run workflow**
3. Selecione a branch `main`
4. Clique em **Run workflow**

## 🔍 Verificação do Deploy

### Verificar Pods

```bash
# Homologação
kubectl get pods -n tech-homolog
kubectl logs -f deployment/encontros-devops -n tech-homolog

# Produção
kubectl get pods -n tech-producao
kubectl logs -f deployment/encontros-devops -n tech-producao
```

### Verificar Serviços

```bash
# Homologação
kubectl get svc -n tech-homolog
kubectl describe svc encontros-devops -n tech-homolog

# Produção
kubectl get svc -n tech-producao
kubectl describe svc encontros-devops -n tech-producao
```

### Acessar Aplicação

```bash
# Obter IP externo (LoadBalancer)
kubectl get svc encontros-devops -n tech-homolog -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
kubectl get svc encontros-devops -n tech-producao -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Acesse: `http://<IP_EXTERNO>`

## 🐛 Troubleshooting

### Pipeline falha no push do Docker

**Erro**: `unauthorized: authentication required`

**Solução**: Verifique se:
1. `DOCKERHUB_USERNAME` está correto
2. `DOCKERHUB_TOKEN` está válido
3. O token tem permissão de **Write**

### Deploy falha no Kubernetes

**Erro**: `error: You must be logged in to the server`

**Solução**:
1. Verifique se o secret `KUBECONFIG` está configurado corretamente
2. Execute localmente: `kubectl get nodes` para validar o kubeconfig

### Pods não iniciam

**Erro**: `ImagePullBackOff`

**Solução**:
1. Verifique se a imagem foi publicada no Docker Hub
2. Confirme que o nome da imagem está correto nos manifests

**Erro**: `CrashLoopBackOff`

**Solução**:
1. Verifique os logs: `kubectl logs <pod-name> -n <namespace>`
2. Confirme que o secret `DATABASE_URL` está correto
3. Verifique se o banco PostgreSQL está acessível

## 📊 Monitoramento

### Métricas Prometheus

A aplicação expõe métricas em `/metrics`:

```bash
kubectl port-forward -n tech-producao svc/encontros-devops 8000:80
curl http://localhost:8000/metrics
```

### Health Check

```bash
kubectl port-forward -n tech-producao svc/encontros-devops 8000:80
curl http://localhost:8000/health
```

## 🔄 Rollback

Se houver problemas após deploy:

```bash
# Ver histórico de deployments
kubectl rollout history deployment/encontros-devops -n tech-producao

# Fazer rollback para versão anterior
kubectl rollout undo deployment/encontros-devops -n tech-producao

# Rollback para uma versão específica
kubectl rollout undo deployment/encontros-devops -n tech-producao --to-revision=2
```

## 🎯 Boas Práticas

1. **Sempre teste localmente antes de fazer push**:
   ```bash
   docker-compose up -d
   # Teste a aplicação
   docker-compose down
   ```

2. **Use Pull Requests**: Permita que o CI valide antes do merge

3. **Monitore os logs**: Após cada deploy, verifique os logs dos pods

4. **Configure alertas**: Integre Prometheus/Grafana para alertas de produção

5. **Documente mudanças**: Use commits descritivos e mensagens claras

## 🔐 Segurança

- ❌ **Nunca** commite secrets no código
- ✅ Use sempre GitHub Secrets para dados sensíveis
- ✅ Rotacione tokens periodicamente (a cada 90 dias)
- ✅ Configure ambientes com proteção de branch
- ✅ Use RBAC no Kubernetes para limitar permissões

## 📚 Referências

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Azure Kubernetes Deploy Action](https://github.com/Azure/k8s-deploy)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Desenvolvido com ❤️ para automação DevOps**
