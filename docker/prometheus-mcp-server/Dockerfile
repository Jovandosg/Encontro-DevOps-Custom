FROM python:3.12-slim

LABEL org.opencontainers.image.title="Prometheus MCP Server" \
      org.opencontainers.image.description="MCP server for Prometheus integration - Encontros DevOps" \
      org.opencontainers.image.source="https://github.com/Jovandosg/Encontro-DevOps-Custom" \
      org.opencontainers.image.authors="Jovandosg" \
      org.opencontainers.image.licenses="MIT"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app \
    PYTHONFAULTHANDLER=1

WORKDIR /app

RUN pip install --no-cache-dir prometheus-mcp-server==1.0.0

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

ENTRYPOINT ["prometheus-mcp-server"]
