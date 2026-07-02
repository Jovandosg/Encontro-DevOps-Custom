# Relatório de Métricas — encontros-devops
**Gerado via MCP Prometheus** | Data: 2026-07-02 | Período: Últimos 30 minutos  
**Prometheus:** `http://20.231.249.89` | **Instrumentação:** Flask (`flask_http_request_*`)

---

## Targets Ativos

```promql
up{job="encontros-devops"}
```

| Pod | Namespace | IP | Status |
|---|---|---|---|
| encontros-devops-7b5756b5dc-rvk4v | tech-producao | 10.244.0.38:8000 | 🟢 UP |
| encontros-devops-7b5756b5dc-p65qm | tech-producao | 10.244.0.137:8000 | 🟢 UP |
| encontros-devops-7b5756b5dc-6b2dv | tech-homolog | 10.244.0.170:8000 | 🟢 UP |
| encontros-devops-7b5756b5dc-crcz8 | tech-homolog | 10.244.0.229:8000 | 🟢 UP |

Todos os 4 pods (2 por ambiente) estão sendo coletados com sucesso pelo Prometheus.

---

## 1. Taxa de Erro HTTP

```promql
sum(rate(flask_http_request_total{job="encontros-devops", status=~"4..|5.."}[30m]))
/ sum(rate(flask_http_request_total{job="encontros-devops"}[30m])) * 100
```

**Resultado: 0.083%**

| Status | Método | Namespace | RPS |
|---|---|---|---|
| 200 | GET | tech-producao | 0.334 req/s |
| 200 | GET | tech-homolog | 0.337 req/s |
| 304 | GET | tech-homolog | 0.0035 req/s |
| 404 | GET | tech-producao | 0.00056 req/s |
| 302 | POST | tech-homolog | ~0 |

**Interpretação:** Apenas erros `404` pontuais em `tech-producao` (~0.056% do tráfego). Nenhum erro `5xx` registrado.

**Status: 🟢 OK** — Threshold saudável < 1%

---

## 2. Latência (Percentis P50 / P95 / P99)

```promql
histogram_quantile(0.50, sum(rate(flask_http_request_duration_seconds_bucket{job="encontros-devops"}[30m])) by (le))
histogram_quantile(0.95, sum(rate(flask_http_request_duration_seconds_bucket{job="encontros-devops"}[30m])) by (le))
histogram_quantile(0.99, sum(rate(flask_http_request_duration_seconds_bucket{job="encontros-devops"}[30m])) by (le))
```

| Percentil | Latência | Threshold OK | Status |
|---|---|---|---|
| **P50** | **2.5 ms** | < 200 ms | 🟢 OK |
| **P95** | **4.75 ms** | < 500 ms | 🟢 OK |
| **P99** | **4.95 ms** | < 1000 ms | 🟢 OK |

**Interpretação:** Latência excepcionalmente baixa. Gap mínimo entre P95 e P99 (0.2 ms) indica distribuição uniforme sem outliers. Excelente performance para uma aplicação Python/FastAPI.

**Status: 🟢 OK**

---

## 3. Throughput (RPS)

```promql
sum(rate(flask_http_request_total{job="encontros-devops"}[30m]))
```

**Resultado: 0.676 req/s** (≈ 40.6 req/min)

| Ambiente | RPS |
|---|---|
| tech-producao | ~0.335 req/s |
| tech-homolog | ~0.341 req/s |

**Interpretação:** Volume baixo e distribuído igualmente entre ambientes. Compatível com ambiente de demonstração/DevOps sem tráfego orgânico significativo.

**Status: 🟡 Baixo** (esperado para ambiente demo)

---

## 4. Utilização de CPU

```promql
sum(rate(container_cpu_usage_seconds_total{namespace=~"tech-.*", container="encontros-devops"}[30m])) by (namespace)
```

| Namespace | CPU Atual | CPU Request | % do Request |
|---|---|---|---|
| tech-producao | 2.05 millicores | 100m | 2.05% |
| tech-homolog | 1.86 millicores | 100m | 1.86% |

| Pod | Namespace | CPU (5min) |
|---|---|---|
| encontros-devops-7b5756b5dc-p65qm | tech-producao | 2.32m |
| encontros-devops-7b5756b5dc-rvk4v | tech-producao | 1.68m |
| encontros-devops-7b5756b5dc-crcz8 | tech-homolog | 1.81m |
| encontros-devops-7b5756b5dc-6b2dv | tech-homolog | 1.98m |

**Interpretação:** Consumo de CPU extremamente baixo — menos de 2.5% do request configurado (100m). CPU request pode ser reduzido para 25m sem impacto.

**Status: 🟢 OK**

---

## 5. Utilização de Memória

```promql
sum(container_memory_working_set_bytes{namespace=~"tech-.*", container="encontros-devops"}) by (namespace, pod)
```

| Pod | Namespace | Memória Atual | Memory Request | % do Request |
|---|---|---|---|---|
| encontros-devops-7b5756b5dc-p65qm | tech-producao | 411 MB | 128 MB | **321%** 🔴 |
| encontros-devops-7b5756b5dc-rvk4v | tech-producao | 407 MB | 128 MB | **318%** 🔴 |
| encontros-devops-7b5756b5dc-crcz8 | tech-homolog | 411 MB | 128 MB | **321%** 🔴 |
| encontros-devops-7b5756b5dc-6b2dv | tech-homolog | 418 MB | 128 MB | **326%** 🔴 |

**Interpretação:** Achado crítico — cada pod consome ~410 MB mas o `resources.requests.memory` está configurado em apenas 128 MB (subutilização de 3.2x). O overhead do runtime Python + FastAPI + dependências explica o consumo real. Sem `limits` definido, o nó pode sofrer pressão de memória em cenário de carga.

**Status: 🔴 Crítico** — Memory requests subutilizados em 321%

---

## Resumo Executivo

| Métrica | Valor | Status |
|---|---|---|
| Taxa de Erro | 0.083% | 🟢 OK |
| Latência P50 | 2.5 ms | 🟢 OK |
| Latência P95 | 4.75 ms | 🟢 OK |
| Latência P99 | 4.95 ms | 🟢 OK |
| Throughput | 0.68 req/s | 🟡 Baixo (esperado) |
| CPU (producao) | 2.05m / 100m | 🟢 OK |
| CPU (homolog) | 1.86m / 100m | 🟢 OK |
| Memória (producao) | 409 MB / 128 MB request | 🔴 Crítico |
| Memória (homolog) | 414 MB / 128 MB request | 🔴 Crítico |

---

## Recomendação Principal

Corrigir `resources` em `k8s/manifests.yaml`:

```yaml
resources:
  requests:
    memory: "450Mi"   # ajustado para uso real (~410 MB) + 10% buffer
    cpu: "25m"        # reduzido do atual 100m (uso real é ~2m)
  limits:
    memory: "512Mi"   # limite seguro acima do uso observado
    cpu: "200m"       # limite para evitar starvation
```

---

> **Validação MCP:** Relatório gerado via MCP Prometheus (`fabriciosveronez/prometheus-mcp-server:v1`)  
> conectado ao Prometheus em `http://20.231.249.89` do cluster AKS `aks-encontros-devops`.
