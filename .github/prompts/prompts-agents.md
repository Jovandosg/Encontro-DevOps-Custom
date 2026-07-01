# Análise Completa do Cluster Kubernetes e Métricas de Aplicação

Execute uma análise abrangente do ambiente Kubernetes realizando duas análises complementares em paralelo:

## Objetivo
Gerar dois relatórios técnicos detalhados sobre:
1. Estado geral do cluster Kubernetes (infraestrutura, workloads e configurações)
2. Métricas de performance e saúde da aplicação "encontros-devops" via Prometheus

## Instruções de Execução

### Execução Paralela dos Agentes
Execute os seguintes agentes **simultaneamente em paralelo** usando múltiplas chamadas do Task tool em uma única mensagem:

1. **Agente k8s-cluster-analyzer**
   - Responsável por: Análise completa da infraestrutura Kubernetes
   - Saída esperada: `relatorio-k8s.md`
   - Conteúdo do relatório:
     - Resumo executivo com status geral do cluster
     - Inventário completo de nodes (nome, status, versão, capacidade)
     - Versões do Kubernetes e compatibilidade
     - Análise de utilização de recursos (CPU, memória, storage)
     - Inventário de aplicações organizadas por namespace
     - Deployments, pods e services em execução
     - Recomendações de otimização priorizadas (crítico, importante, desejável)
     - Próximos passos e plano de implementação

2. **Agente prometheus-k8s-analyzer**
   - Responsável por: Análise de métricas da aplicação encontros-devops
   - Saída esperada: `relatorio-metricas-prometheus.md`
   - Conteúdo do relatório:
     - Taxa de erro (requisições HTTP 4xx e 5xx)
     - Tempo de resposta (percentis P50, P95, P99)
     - Throughput (requisições por segundo)
     - Utilização de recursos (CPU e memória vs limits)
     - Para cada métrica: consulta PromQL, valor atual, análise, status e recomendações
     - Resumo executivo do estado da aplicação
     - Correlações entre métricas
     - Tendências e problemas críticos
     - Recomendações técnicas acionáveis

## Formato dos Relatórios
- Ambos os relatórios devem ser gerados em **português brasileiro**
- Formato: **Markdown**
- Localização: Raiz do repositório do projeto
- Nomenclatura:
  - Cluster K8s: `relatorio-k8s.md`
  - Métricas Prometheus: `relatorio-metricas-prometheus.md`

## Critérios de Qualidade
- Dados específicos e concretos (números, nomes, versões)
- Recomendações acionáveis com passos claros
- Análise contextualizada explicando o "porquê"
- Linguagem técnica profissional
- Priorização clara de problemas e melhorias

## Resultado Esperado
Ao final da execução paralela, você deve ter dois arquivos markdown salvos no repositório, cada um contendo análises detalhadas e independentes, mas complementares, sobre o ambiente Kubernetes e a aplicação encontros-devops.