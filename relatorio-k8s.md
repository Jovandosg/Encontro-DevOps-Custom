# Relatório de Análise do Cluster Kubernetes

**Cluster:** aks-encontros-devops  
**Data da Análise:** 2026-07-02  
**Analista:** GitHub Copilot (k8s-cluster-analyzer)  

---

## Resumo Executivo

| Atributo | Valor |
|---|---|
| **Status Geral** | ⚠️ Atenção Necessária |
| **Total de Nodes** | 1 (single-node cluster) |
| **Total de Pods** | 24 (23 Running, 1 Error) |
| **Namespaces de Aplicação** | 3 (default, postgres, tech-homolog, tech-producao) |
| **Serviços com IP Externo** | 4 (LoadBalancer) |
| **Uso de CPU (Node)** | 186m / 1900m (**9%**) |
| **Uso de Memória (Node)** | 2617Mi / 5930Mi (**44%**) |

### Principais Descobertas

1. ✅ **Aplicação operacional** — todos os pods de workload estão Running com probes configuradas
2. ❌ **Pod `grafana-test` em estado Error** — resquício de teste do Helm, precisa ser removido
3. ❌ **Sem HPA configurado** — nenhum namespace possui Horizontal Pod Autoscaler
4. ❌ **Imagem com tag `latest`** — encontros-devops usa tag não-pinada em produção
5. ⚠️ **Single-node cluster** — ausência de alta disponibilidade para workloads
6. ⚠️ **Sem NetworkPolicy** nos namespaces de aplicação — risco de segurança
7. ⚠️ **Grafana e Prometheus expostos publicamente** sem autenticação de rede

### Prioridades de Ação Imediata

- Remover o pod `grafana-test` em erro
- Fixar a tag de imagem em produção (substituir `latest` por versão semântica)
- Implementar NetworkPolicy nos namespaces `tech-homolog` e `tech-producao`
- Configurar HPA para as aplicações

---

## 1. Infraestrutura — Nodes do Cluster

### 1.1 Inventário de Nodes

| Campo | Valor |
|---|---|
| **Nome** | `aks-default-91270569-vmss000000` |
| **Status** | ✅ Ready |
| **Versão Kubernetes** | v1.35.5 |
| **Sistema Operacional** | Ubuntu 24.04.4 LTS |
| **Kernel** | 6.8.0-1059-azure |
| **Container Runtime** | containerd 2.3.2-1 |
| **IP Interno** | 10.224.0.4 |
| **IP Externo** | Nenhum (node privado) |

### 1.2 Capacidade e Alocação de Recursos

| Recurso | Capacidade Total | Alocável | Em Uso | Utilização |
|---|---|---|---|---|
| **CPU** | 2 cores (2000m) | 1900m | 186m | **9%** ✅ |
| **Memória** | ~7.75 GB (8129268Ki) | ~5.65 GB (5929716Ki) | 2617Mi | **44%** ✅ |

> **Avaliação:** Utilização atual dentro de parâmetros saudáveis. O cluster possui headroom significativo de CPU. Memória em 44% é adequado, mas monitorar tendência de crescimento dado que a aplicação encontros-devops consome ~200Mi por réplica.

### 1.3 Análise de Alta Disponibilidade

> ⚠️ **Problema Crítico:** O cluster possui apenas **1 node**. Qualquer falha no node resulta em indisponibilidade total de todos os workloads. Para ambientes de produção, recomenda-se no mínimo **3 nodes** em zonas de disponibilidade distintas.

---

## 2. Inventário de Aplicações por Namespace

### 2.1 Namespace: `default` — Observabilidade

| Pod | Status | CPU Real | Memória Real | Observação |
|---|---|---|---|---|
| `grafana-6756dd7fc4-cjd9q` | ✅ Running (1/1) | 2m | 97Mi | Saudável |
| `grafana-test` | ❌ **Error** (0/1) | — | — | **Remover — pod de teste do Helm** |
| `prometheus-kube-state-metrics-65cfcb49cc-pdcg8` | ✅ Running (1/1) | 2m | 16Mi | Saudável |
| `prometheus-prometheus-node-exporter-d7gtk` | ✅ Running (1/1) | 3m | 13Mi | Saudável |
| `prometheus-server-7bb6fbbcdb-mncjc` | ✅ Running (2/2) | 6m | 164Mi | Maior consumidor de memória no namespace |

**Deployments:**
| Deployment | Réplicas | Imagem |
|---|---|---|
| `grafana` | 1/1 | `docker.io/grafana/grafana:12.0.2` |
| `prometheus-kube-state-metrics` | 1/1 | `registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.15.0` |
| `prometheus-server` | 1/1 | `quay.io/prometheus/prometheus:v3.4.1` |

---

### 2.2 Namespace: `postgres` — Banco de Dados

| Pod | Status | CPU Real | Memória Real |
|---|---|---|---|
| `postgres-7d9fbfbd5b-2tv7d` | ✅ Running (1/1) | 11m | 56Mi |

**Configuração do Container:**
| Atributo | Valor |
|---|---|
| Imagem | `postgres:16` |
| CPU Request / Limit | 250m / 500m |
| Memória Request / Limit | 256Mi / 512Mi |
| LivenessProbe | ✅ Configurada |
| ReadinessProbe | ✅ Configurada |

**Storage:**
| PVC | Tamanho | Modo de Acesso | StorageClass | Política de Retenção |
|---|---|---|---|---|
| `postgres-pvc` | 10Gi | RWO | `default` | **Delete** ⚠️ |

> ⚠️ **Risco:** O PersistentVolume usa `Reclaim Policy: Delete`. Isso significa que **ao deletar o PVC, os dados serão permanentemente perdidos**. Alterar para `Retain` em produção.

> ⚠️ **Risco:** O PostgreSQL está rodando como `Deployment` (não `StatefulSet`). Para bancos de dados, `StatefulSet` é a abordagem correta para garantir identidade estável e ordem de inicialização.

---

### 2.3 Namespace: `tech-homolog` — Homologação

| Pod | Status | CPU Real | Memória Real |
|---|---|---|---|
| `encontros-devops-7b5756b5dc-6b2dv` | ✅ Running (1/1) | 1m | 208Mi |
| `encontros-devops-7b5756b5dc-crcz8` | ✅ Running (1/1) | 1m | 204Mi |

**Configuração dos Containers:**
| Atributo | Valor |
|---|---|
| Imagem | `jovandosg/encontros-devops:latest` ⚠️ |
| CPU Request / Limit | 100m / 500m |
| Memória Request / Limit | 128Mi / 512Mi |
| LivenessProbe | ✅ Configurada |
| ReadinessProbe | ✅ Configurada |
| Réplicas | 2/2 |

> ⚠️ **Uso da tag `latest`:** Não é possível garantir reprodutibilidade dos deploys. Em caso de rollback, não se sabe qual versão está em execução.

---

### 2.4 Namespace: `tech-producao` — Produção

| Pod | Status | CPU Real | Memória Real |
|---|---|---|---|
| `encontros-devops-7b5756b5dc-p65qm` | ✅ Running (1/1) | 2m | 205Mi |
| `encontros-devops-7b5756b5dc-rvk4v` | ✅ Running (1/1) | 1m | 203Mi |

**Configuração dos Containers:**
| Atributo | Valor |
|---|---|
| Imagem | `jovandosg/encontros-devops:latest` ❌ |
| CPU Request / Limit | 100m / 500m |
| Memória Request / Limit | 128Mi / 512Mi |
| LivenessProbe | ✅ Configurada |
| ReadinessProbe | ✅ Configurada |
| Réplicas | 2/2 |

> ❌ **Crítico em Produção:** Uso de `latest` em `tech-producao` é uma violação direta das boas práticas. Uma nova imagem publicada sem versionamento pode ser puxada automaticamente e quebrar o ambiente de produção.

---

### 2.5 Namespace: `kube-system` — Componentes do Sistema

| Pod | Status | Observação |
|---|---|---|
| `azure-cns-8d852` | ✅ Running (2/2) | Azure Container Networking |
| `azure-ip-masq-agent-dh656` | ✅ Running (1/1) | IP masquerading |
| `cloud-node-manager-ffskw` | ✅ Running (1/1) | Gerenciamento de nó cloud |
| `coredns-55f58ccb97-kmb5m` | ✅ Running (1/1) | DNS do cluster |
| `coredns-55f58ccb97-sz9k7` | ✅ Running (1/1) | DNS do cluster (HA) |
| `coredns-autoscaler-6b6676685f-rpvm7` | ✅ Running (1/1) | Auto-scaling de DNS |
| `csi-azuredisk-node-vtc42` | ✅ Running (3/3) | Driver Azure Disk |
| `csi-azurefile-node-xctdk` | ✅ Running (4/4) | Driver Azure Files |
| `konnectivity-agent-5f987957b5-jd5pg` | ✅ Running (1/1) | Conectividade com API server |
| `konnectivity-agent-5f987957b5-qvn2t` | ✅ Running (1/1) | Conectividade com API server (HA) |
| `konnectivity-agent-autoscaler-d8f888d85-86zvq` | ✅ Running (1/1) | |
| `kube-proxy-nzqtt` | ✅ Running (1/1) | Proxy de rede |
| `metrics-server-85bd4cbc84-7qhs5` | ✅ Running (2/2) | Métricas de recursos |
| `metrics-server-85bd4cbc84-j9n9t` | ✅ Running (2/2) | Métricas de recursos (HA) |

> ✅ Todos os componentes do sistema estão saudáveis.

---

## 3. Rede e Serviços Expostos

### 3.1 Serviços com IP Público (LoadBalancer)

| Namespace | Serviço | IP Externo | Porta | Acesso |
|---|---|---|---|---|
| `default` | `grafana` | **52.147.220.92** | 80 | 🌐 Público |
| `default` | `prometheus-server` | **20.231.249.89** | 80 | 🌐 Público |
| `tech-homolog` | `encontros-devops` | **172.171.158.13** | 80 | 🌐 Público |
| `tech-producao` | `encontros-devops` | **4.156.99.16** | 80 | 🌐 Público |

### 3.2 Serviços Internos (ClusterIP)

| Namespace | Serviço | Cluster-IP | Porta |
|---|---|---|---|
| `default` | `kubernetes` | 10.0.0.1 | 443 |
| `default` | `prometheus-kube-state-metrics` | 10.0.182.106 | 8080 |
| `default` | `prometheus-node-exporter` | 10.0.18.221 | 9100 |
| `kube-system` | `kube-dns` | 10.0.0.10 | 53/UDP, 53/TCP |
| `kube-system` | `metrics-server` | 10.0.217.215 | 443 |
| `postgres` | `postgres` | 10.0.64.200 | 5432 |

### 3.3 Análise de Segurança de Rede

> ❌ **Grafana e Prometheus expostos na internet sem restrição de rede.** Qualquer usuário com o IP externo pode acessar os dashboards de monitoramento. Isso expõe métricas internas do cluster e, caso a autenticação seja fraca, possibilita acesso não autorizado.

> ℹ️ Não há **Ingress Controller** configurado. Cada serviço usa um LoadBalancer individual, o que:
> - Aumenta o custo (cada LoadBalancer tem custo no Azure)
> - Dificulta o gerenciamento de SSL/TLS centralizado
> - Impede o roteamento baseado em hostname/path

---

## 4. Uso de Recursos — Análise Detalhada

### 4.1 Consumo por Pod (Ordenado por CPU)

| Namespace | Pod | CPU | Memória |
|---|---|---|---|
| `postgres` | `postgres-7d9fbfbd5b-2tv7d` | 11m | 56Mi |
| `default` | `prometheus-server` | 6m | 164Mi |
| `kube-system` | `konnectivity-agent` (jd5pg) | 4m | 23Mi |
| `default` | `prometheus-node-exporter` | 3m | 13Mi |
| `kube-system` | `metrics-server` (7qhs5) | 2m | 33Mi |
| `kube-system` | `azure-cns-8d852` | 2m | 89Mi |
| `tech-producao` | `encontros-devops` (p65qm) | 2m | 205Mi |
| `default` | `prometheus-kube-state-metrics` | 2m | 16Mi |
| `kube-system` | `coredns` (kmb5m) | 2m | 24Mi |
| `kube-system` | `coredns` (sz9k7) | 2m | 24Mi |
| `kube-system` | `metrics-server` (j9n9t) | 2m | 35Mi |
| `default` | `grafana` | 2m | 97Mi |
| `kube-system` | `csi-azurefile-node` | 2m | 134Mi |
| `kube-system` | `konnectivity-agent` (qvn2t) | 2m | 24Mi |
| `kube-system` | `csi-azuredisk-node` | 1m | 137Mi |
| `kube-system` | `kube-proxy` | 1m | 24Mi |
| `kube-system` | `konnectivity-agent-autoscaler` | 1m | 10Mi |
| `kube-system` | `coredns-autoscaler` | 1m | 12Mi |
| `kube-system` | `cloud-node-manager` | 1m | 90Mi |
| `tech-homolog` | `encontros-devops` (6b2dv) | 1m | 208Mi |
| `tech-homolog` | `encontros-devops` (crcz8) | 1m | 204Mi |
| `kube-system` | `azure-ip-masq-agent` | 1m | 9Mi |
| `tech-producao` | `encontros-devops` (rvk4v) | 1m | 203Mi |

### 4.2 Distribuição de Memória por Namespace

| Namespace | Total de Memória em Uso |
|---|---|
| `tech-homolog` | ~412Mi (4 réplicas × ~205Mi) |
| `tech-producao` | ~408Mi |
| `default` (observabilidade) | ~290Mi |
| `kube-system` | ~606Mi (estimado) |
| `postgres` | ~56Mi |
| **Total estimado** | **~1.8 GB** de 5.65 GB alocáveis |

> ✅ O cluster está utilizando apenas ~32% da memória alocável. Há capacidade para crescimento.

---

## 5. Governança e Configuração

### 5.1 Auto-scaling

| Recurso | Status |
|---|---|
| Horizontal Pod Autoscaler (HPA) | ❌ Não configurado em nenhum namespace |
| Cluster Autoscaler | ❌ Não detectado (cluster single-node) |

### 5.2 Políticas de Rede

| Namespace | NetworkPolicy |
|---|---|
| `kube-system` | ✅ `konnectivity-agent` protegido |
| `default` | ❌ Sem NetworkPolicy |
| `postgres` | ❌ Sem NetworkPolicy (banco exposto para todos os pods) |
| `tech-homolog` | ❌ Sem NetworkPolicy |
| `tech-producao` | ❌ Sem NetworkPolicy |

### 5.3 Cotas e Limites por Namespace

| Recurso | Status |
|---|---|
| ResourceQuota | ❌ Não configurado em nenhum namespace |
| LimitRange | ❌ Não configurado em nenhum namespace |

### 5.4 Ingress

| Recurso | Status |
|---|---|
| Ingress Controller | ❌ Não instalado |
| Recursos Ingress | ❌ Nenhum |

---

## 6. Recomendações de Otimização

### 🔴 Alta Prioridade (Crítico)

#### 6.1 Remover pod `grafana-test` em estado Error
```bash
kubectl delete pod grafana-test -n default
```
O pod é um artefato do teste de instalação do Helm Chart do Grafana. Está em estado `Error` e consumindo um slot no cluster.

---

#### 6.2 Substituir tag `latest` por versão semântica em produção
Nos manifests de `tech-producao` e `tech-homolog`, alterar:
```yaml
# ANTES
image: jovandosg/encontros-devops:latest

# DEPOIS (exemplo)
image: jovandosg/encontros-devops:v1.2.3
```
Implementar digest pinning no pipeline de CI/CD para garantir imutabilidade.

---

#### 6.3 Implementar NetworkPolicy para o namespace `postgres`
Restringir acesso ao banco de dados apenas para pods autorizados:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-only-app
  namespace: postgres
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: tech-producao
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: tech-homolog
      ports:
        - protocol: TCP
          port: 5432
```

---

#### 6.4 Alterar política de retenção do PersistentVolume do Postgres

O PV atual tem `Reclaim Policy: Delete`, o que significa que ao deletar o PVC os dados são perdidos permanentemente.

```bash
# Obter o nome do PV
kubectl get pvc postgres-pvc -n postgres -o jsonpath='{.spec.volumeName}'

# Alterar a reclaim policy para Retain
kubectl patch pv pvc-ee18940b-f52e-453e-b908-4d170cdb05ff \
  -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

---

#### 6.5 Migrar Postgres de Deployment para StatefulSet

O PostgreSQL sendo gerenciado por um `Deployment` não garante identidade estável de pod. Migrar para `StatefulSet` é essencial para:
- Garantir identidade estável do pod (dns, storage)
- Ordem controlada de inicialização/encerramento
- Volume dedicado por réplica (para futuro scale-out com réplicas de leitura)

---

### 🟡 Média Prioridade (Importante)

#### 6.6 Configurar Horizontal Pod Autoscaler (HPA)

Ambas as aplicações (`tech-homolog` e `tech-producao`) têm requests/limits definidos, o que habilita o HPA. Implementar scaling automático:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: encontros-devops-hpa
  namespace: tech-producao
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: encontros-devops
  minReplicas: 2
  maxReplicas: 6
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

---

#### 6.7 Instalar Ingress Controller (NGINX ou Azure App Gateway)

Substituir 4 LoadBalancers individuais por um único Ingress Controller centraliza o roteamento e reduz custos:

```bash
# Instalar NGINX Ingress Controller via Helm
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

**Economia estimada:** 3 LoadBalancers a menos (~$0.025/hora cada = ~$54/mês de economia)

---

#### 6.8 Proteger Grafana e Prometheus contra acesso público

Atualmente, Grafana (52.147.220.92) e Prometheus (20.231.249.89) estão acessíveis publicamente. Implementar uma das opções:
- Mover para `ClusterIP` e acessar via port-forward durante análise
- Adicionar autenticação básica no Ingress
- Restringir IPs permitidos via NSG no Azure

---

#### 6.9 Adicionar segundo node para alta disponibilidade

Para produção, expandir o node pool:
```bash
az aks nodepool update \
  --resource-group <rg> \
  --cluster-name aks-encontros-devops \
  --name default \
  --node-count 2
```

Idealmente, usar **3 nodes em availability zones distintas** para garantir que a falha de uma zona não afete a aplicação.

---

### 🟢 Baixa Prioridade (Desejável)

#### 6.10 Implementar ResourceQuota por namespace

Prevenir que um namespace consuma recursos excessivos impactando outros:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota-producao
  namespace: tech-producao
spec:
  hard:
    requests.cpu: "500m"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 4Gi
    pods: "10"
```

---

#### 6.11 Implementar LimitRange

Garantir que pods sem requests/limits não sejam admitidos no cluster:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: tech-producao
spec:
  limits:
    - default:
        cpu: 200m
        memory: 256Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
      type: Container
```

---

#### 6.12 Adicionar tags de custo nos recursos do cluster

Conforme definido nas instruções do projeto, garantir que os recursos do AKS no Azure possuam as tags obrigatórias:
- `Environment`, `Application`, `Owner`, `CostCenter`, `ManagedBy`

---

#### 6.13 Habilitar Azure Policy para governança de cluster

Ativar o add-on Azure Policy para AKS para enforcement automático de:
- Proibir imagens com tag `latest`
- Exigir probes de liveness/readiness
- Bloquear containers privilegiados
- Exigir requests e limits em todos os containers

---

## 7. Próximos Passos

### Ações Imediatas (Hoje)

| Prioridade | Ação | Responsável | Tempo Estimado |
|---|---|---|---|
| 🔴 1 | Remover pod `grafana-test` em erro | DevOps | 2 min |
| 🔴 2 | Alterar tag de imagem de `latest` para versão semântica | Dev | 30 min |
| 🔴 3 | Implementar NetworkPolicy no namespace `postgres` | DevOps | 15 min |
| 🔴 4 | Alterar reclaim policy do PV do Postgres para `Retain` | DevOps | 5 min |

### Plano de Implementação (Sprint)

| Semana | Ação |
|---|---|
| Semana 1 | Migrar Postgres para StatefulSet + configurar NetworkPolicies em todos namespaces |
| Semana 2 | Instalar Ingress Controller + configurar Ingress para todos os serviços |
| Semana 3 | Configurar HPA para tech-homolog e tech-producao |
| Semana 4 | Adicionar segundo node ao cluster + configurar ResourceQuota e LimitRange |

### Métricas para Acompanhamento

| Métrica | Valor Atual | Meta |
|---|---|---|
| Disponibilidade da aplicação | N/D | > 99.9% |
| Uso de CPU do node | 9% | < 70% |
| Uso de memória do node | 44% | < 75% |
| Pods em estado não-Running | 1 (grafana-test) | 0 |
| Serviços com LoadBalancer | 4 | 1 (Ingress) |
| Namespaces com NetworkPolicy | 1 (kube-system) | Todos |
| Namespaces com ResourceQuota | 0 | Todos os de aplicação |

---

## Apêndice — Comandos Úteis de Monitoramento

```bash
# Configurar KUBECONFIG
export KUBECONFIG=/home/jsgoncalves/pessoal/Encontro-DevOps-Custom/aks-iac/kubeconfig

# Verificar saúde dos pods em tempo real
kubectl get pods -A -w

# Monitorar uso de recursos
kubectl top nodes && kubectl top pods -A --sort-by=memory

# Logs da aplicação de produção
kubectl logs -n tech-producao -l app=encontros-devops --tail=100 -f

# Acessar Grafana via port-forward (sem expor publicamente)
kubectl port-forward svc/grafana -n default 3000:80

# Acessar Prometheus via port-forward
kubectl port-forward svc/prometheus-server -n default 9090:80

# Verificar eventos de warning
kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp'
```

---

*Relatório gerado automaticamente em 2026-07-02 pela análise do cluster AKS `aks-encontros-devops`.*
