KUBECONFIG_PATH := $(CURDIR)/kubeconfig
export KUBECONFIG := $(KUBECONFIG_PATH)

.PHONY: init apply destroy plan kubeconfig

init:
	terraform init

plan:
	terraform plan -out=tfplan

apply:
	terraform apply tfplan
	@echo "\n✅ Cluster pronto. Execute no seu terminal:"
	@echo "   export KUBECONFIG=$(KUBECONFIG_PATH)"

destroy:
	terraform destroy
	@rm -f $(KUBECONFIG_PATH)
	@echo "\n🗑️  Cluster destruído e kubeconfig removido."

kubeconfig:
	terraform apply -target=local_sensitive_file.kubeconfig
	@echo "\n✅ kubeconfig atualizado em: $(KUBECONFIG_PATH)"
	@echo "   Execute: export KUBECONFIG=$(KUBECONFIG_PATH)"
