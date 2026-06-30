# Encontros DevOps - Customizado Avanade Brasil

Esta é uma versão customizada da aplicação Encontros Tech, adaptada com a identidade visual da Avanade Brasil para os **Encontros DevOps**.

## 🎨 Customizações Realizadas

*   **Nome da Imagem:** `jovandosg/encontros-devops`
*   **Identidade Visual:** Padrão de cores Avanade Brasil com laranja predominante (`#FF7A00`).
*   **Logotipo:** Logotipo oficial da Avanade inserido no canto superior esquerdo.
*   **Rodapé Customizado:**
    *   Lado Esquerdo: "Criado por Jovando Goncalves"
    *   Lado Direito: "Encontros DevOps"

## 🚀 Como executar localmente (Docker)

```bash
docker run -d \
  --name encontros-devops \
  -p 8000:8000 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  jovandosg/encontros-devops:latest
```

## ☸️ Deploy em Kubernetes

Para realizar o deploy no Kubernetes, utilize o arquivo `k8s/deployment.yaml` atualizando a imagem para `jovandosg/encontros-devops:latest`.

## 🛠️ Pipeline CI/CD

O projeto inclui um workflow do GitHub Actions em `.github/workflows/main.yml` que automatiza:
1. O build da imagem Docker.
2. O push para o Docker Hub em `jovandosg/encontros-devops`.

*Nota: Certifique-se de configurar os secrets `DOCKERHUB_USERNAME` e `DOCKERHUB_TOKEN` no seu repositório GitHub.*
