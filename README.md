# Encontros DevOps 🚀

Aplicação web para gerenciamento de eventos de tecnologia, desenvolvida com Flask e identidade visual **Avanade**. Inclui CI/CD automatizado com GitHub Actions, deploy para Kubernetes e observabilidade com Prometheus.

![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Python](https://img.shields.io/badge/python-3.11+-blue.svg?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/flask-%23000.svg?style=for-the-badge&logo=flask&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

## 📋 Sobre o Projeto

**Encontros DevOps** é uma aplicação web completa que permite criar, visualizar e gerenciar eventos de tecnologia. Com design moderno e identidade visual **Avanade** (laranja #FF7A00), a aplicação oferece:

- ✨ Interface web responsiva com identidade visual Avanade
- 🎨 Logo Avanade no cabeçalho
- 📊 API REST completa
- 🔍 Sistema de busca e filtros
- 📈 Métricas Prometheus nativas
- 🐳 Containerização com Docker
- ☸️ Deploy automatizado para Kubernetes
- 🔄 CI/CD com GitHub Actions

## 🚀 Funcionalidades

### Gerenciamento de Eventos
- ✅ Criar eventos com título, descrição, data, local e tecnologias
- ✅ Visualizar lista completa de eventos
- ✅ Editar eventos com token de segurança
- ✅ Buscar eventos por título, descrição ou localização

### Observabilidade
- 📊 Métricas Prometheus em `/metrics`
- 🏥 Health check em `/health`
- 📝 Logging estruturado configurável
- 🔍 Rastreamento de requests

### DevOps
- 🐳 Docker e Docker Compose para desenvolvimento
- ☸️ Manifests Kubernetes prontos para produção
- 🔄 Pipeline CI/CD automatizado
- 🚀 Deploy para homologação e produção
- 🔐 Gestão de secrets com Kubernetes

## 🛠️ Tecnologias

### Backend
- **Flask 3.0.0** - Framework web
- **SQLAlchemy 2.0.43** - ORM
- **PostgreSQL** - Banco de dados
- **Gunicorn 21.2.0** - Servidor WSGI
- **Pydantic 2.11.7** - Validação de dados

### Frontend
- **Jinja2 3.1.6** - Templates
- **HTML5/CSS3** - Interface responsiva
- **Bootstrap 5.3.0** - Framework CSS
- **JavaScript** - Interatividade

### DevOps
- **Docker** - Containerização
- **Kubernetes** - Orquestração
- **GitHub Actions** - CI/CD
- **Prometheus** - Métricas

## 📦 Estrutura do Projeto

```
.
├── .github/
│   └── workflows/
│       └── main.yml              # Pipeline CI/CD
├── core/
│   ├── database.py               # Conexão com banco
│   └── settings.py               # Configurações
├── k8s/
│   └── manifests.yaml            # Manifests Kubernetes
├── models/
│   └── event_model.py            # Modelo de dados
├── routes/
│   ├── api_routes.py             # Rotas da API
│   └── web_routes.py             # Rotas web
├── schemas/
│   └── event_schema.py           # Schemas Pydantic
├── static/
│   ├── css/
│   │   └── style.css             # Estilos (cor Avanade #FF7A00)
│   ├── img/
│   │   └── avanade_logo.png      # Logo Avanade
│   └── js/
│       └── script.js             # JavaScript
├── templates/
│   ├── base.html                 # Template base
│   ├── index.html                # Página inicial
│   ├── event_form.html           # Formulário de eventos
│   └── edit_event.html           # Edição de eventos
├── tests/                        # Testes automatizados
├── docker-compose.yml            # Ambiente de desenvolvimento
├── Dockerfile                    # Imagem Docker
├── requirements.txt              # Dependências Python
├── .env.example                  # Exemplo de variáveis
├── CI-CD-SETUP.md               # Guia de CI/CD
└── README.md                     # Este arquivo
```

## 🔧 Configuração

### Variáveis de Ambiente

Copie `.env.example` para `.env` e configure:

```bash
DATABASE_URL=postgresql://user:password@localhost:5432/encontros_devops
APP_TITLE=Encontros DevOps
DEBUG=false
HOST=0.0.0.0
PORT=8000
LOG_LEVEL=INFO
```

## 🚀 Execução Local

### Com Docker Compose (Recomendado)

```bash
# Clonar repositório
git clone https://github.com/Jovandosg/Encontro-DevOps.git
cd Encontro-DevOps

# Subir aplicação + PostgreSQL
docker-compose up -d

# Verificar logs
docker-compose logs -f web

# Acessar aplicação
# http://localhost:8000
```

### Com Python (Desenvolvimento)

```bash
# Instalar dependências
py -m pip install -r requirements.txt

# Configurar variáveis
cp .env.example .env

# Rodar aplicação (precisa PostgreSQL rodando)
py main.py
```

### Parar containers

```bash
docker-compose down
```

## 🔄 CI/CD Pipeline

### Fluxo Automatizado

1. **Push/PR para main** → Executa testes
2. **Merge para main** → Build e push Docker
3. **Deploy automático** → Homologação (tech-homolog)
4. **Aprovação manual** → Produção (tech-producao)

### Configuração

Veja o guia completo: **[CI-CD-SETUP.md](CI-CD-SETUP.md)**

#### Secrets necessários no GitHub:

**Variables** (Settings → Secrets and variables → Actions → Variables):
- `ENABLE_DOCKER_PUSH=true`
- `ENABLE_CD=true`
- `DOCKERHUB_USERNAME=seu-usuario`

**Secrets** (Settings → Secrets and variables → Actions → Secrets):
- `DOCKERHUB_TOKEN` - Token do Docker Hub
- `KUBECONFIG` - Config do cluster Kubernetes
- `DATABASE_URL` - URL do PostgreSQL

## ☸️ Deploy Kubernetes

### Criar Secrets

```bash
kubectl create secret generic encontros-devops-secrets \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --namespace=tech-producao
```

### Deploy Manual

```bash
kubectl apply -f k8s/manifests.yaml -n tech-producao
```

### Verificar Deploy

```bash
# Ver pods
kubectl get pods -n tech-producao

# Ver logs
kubectl logs -f deployment/encontros-devops -n tech-producao

# Ver serviço
kubectl get svc encontros-devops -n tech-producao
```

### Acessar Aplicação

```bash
# Obter IP externo
kubectl get svc encontros-devops -n tech-producao -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Ou usar port-forward para teste
kubectl port-forward svc/encontros-devops 8000:80 -n tech-producao
# http://localhost:8000
```

## 📊 Monitoramento

### Health Check

```bash
curl http://localhost:8000/health
```

### Métricas Prometheus

```bash
curl http://localhost:8000/metrics
```

### Endpoints da API

```bash
# Listar eventos
curl http://localhost:8000/api/events/

# Criar evento
curl -X POST http://localhost:8000/api/events/ \
  -H "Content-Type: application/json" \
  -d '{
    "title": "DevOps Meetup",
    "description": "Encontro sobre práticas DevOps",
    "date": "2026-07-15T19:00:00",
    "location": "São Paulo - SP",
    "technologies": ["Docker", "Kubernetes", "CI/CD"]
  }'
```

## 🧪 Testes

```bash
# Rodar testes
pytest tests/ -v

# Com cobertura
pytest tests/ -v --cov=. --cov-report=html
```

## 🎨 Identidade Visual

### Cores Avanade
- **Primary Orange**: `#FF7A00`
- **Dark Orange**: `#E66A00`
- **Light Orange**: `#FF8F33`

### Logo
Logo da Avanade localizada em: `static/img/avanade_logo.png`

### Footer
- Esquerda: "Criado por Jovando Goncalves"
- Direita: "Encontros DevOps"

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit suas mudanças: `git commit -m 'Adiciona nova funcionalidade'`
4. Push para a branch: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📧 Contato

**Jovando Gonçalves**
- GitHub: [@Jovandosg](https://github.com/Jovandosg)
- Email: jovando@example.com

## 🙏 Agradecimentos

- **Avanade** - Identidade visual
- **Comunidade DevOps** - Inspiração e conhecimento

---

**Desenvolvido com ❤️ para a comunidade tech brasileira**

🔗 **Links Úteis:**
- [Documentação CI/CD](CI-CD-SETUP.md)
- [Repositório GitHub](https://github.com/Jovandosg/Encontro-DevOps)
- [Docker Hub](https://hub.docker.com/r/jovandosg/encontros-devops)
