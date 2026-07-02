KUBECONFIG_PATH := $(CURDIR)/kubeconfig
export KUBECONFIG := $(KUBECONFIG_PATH)

.PHONY: init apply destroy plan kubeconfig setup observability

setup:
	@echo "Gerando terraform.tfvars com subscription_id da conta Azure ativa..."
	@SUB_ID=$$(az account show --query id -o tsv 2>/dev/null) && \
	if [ -z "$$SUB_ID" ]; then echo "❌ Erro: faça 'az login' primeiro." && exit 1; fi && \
	sed "s/00000000-0000-0000-0000-000000000000/$$SUB_ID/" terraform.tfvars.example > terraform.tfvars && \
	echo "✅ terraform.tfvars criado com subscription_id=$$SUB_ID"

init:
	terraform init

plan:
	terraform plan -out=tfplan

apply:
	terraform apply tfplan
	@echo "\n⏳ Deployando stack de observabilidade (Prometheus + Grafana)..."
	@$(MAKE) observability
	@echo "\n✅ Cluster e observabilidade prontos."
	@echo "   KUBECONFIG já configurado em: $(KUBECONFIG_PATH)"

destroy:
	terraform destroy
	@rm -f $(KUBECONFIG_PATH)
	@echo "\n🗑️  Cluster destruído e kubeconfig removido."

kubeconfig:
	terraform apply -target=local_sensitive_file.kubeconfig
	@echo "\n✅ kubeconfig atualizado em: $(KUBECONFIG_PATH)"
	@echo "   Execute: export KUBECONFIG=$(KUBECONFIG_PATH)"

observability:
	kubectl apply -f ../prometheus/manifestos.yaml
	@echo "\n✅ Stack de observabilidade deployada."
	@echo "   Aguarde ~60s e verifique os IPs com:"
	@echo "   kubectl get svc grafana prometheus-server -n default"
