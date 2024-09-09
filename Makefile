NAMESPACE_SECRET_PRINTER=webserver
NAMESPACE_ARGOCD=argocd
KUBECONFIG=$(HOME)/.kube/config
VAULT_NAMESPACE=vault
VAULT_RELEASE_NAME=vault
VAULT_VERSION=0.25.0  # Change this to a specific Vault version if necessary

.PHONY: help install-argo uninstall-argo add-hashicorp-repo install-vault uninstall-vault apply-webserver-app clean

# Default target: shows usage information
help:
	@echo "  install-argo     - Install ArgoCD 7.5.2"
	@echo "  uninstall-argo   - Uninstall ArgoCD 7.5.2"
	@echo "  install-vault    - Install HashiCorp Vault with Helm"
	@echo "  uninstall-vault  - Uninstall HashiCorp Vault"
	@echo "  clean            - Cleanup resources"
	@echo "  apply-webserver-app - Create ArgoCD Application for Webserver"

# Installs ArgoCD 7.5.2
install-argo:
	helm dependency build argocd
	helm upgrade --install argocd argocd --namespace $(NAMESPACE_ARGOCD) --values argocd/values.yaml --create-namespace

# Uninstalls ArgoCD 7.5.2
uninstall-argo:
	helm uninstall argocd --namespace $(NAMESPACE_ARGOCD)

# Add HashiCorp Helm repository (if not already added) and update it
add-hashicorp-repo:
	helm repo add hashicorp https://helm.releases.hashicorp.com || true
	helm repo update

# Install HashiCorp Vault with Helm
install-vault: add-hashicorp-repo
	helm upgrade --install $(VAULT_RELEASE_NAME) hashicorp/vault --version $(VAULT_VERSION) \
	--namespace $(VAULT_NAMESPACE) --kubeconfig $(KUBECONFIG) --create-namespace --set "server.dev.enabled=true"

# Uninstall HashiCorp Vault
uninstall-vault:
	helm uninstall $(VAULT_RELEASE_NAME) --namespace $(VAULT_NAMESPACE) --kubeconfig $(KUBECONFIG)

# Create ArgoCD Application for the Webserver
apply-webserver-app:
	kubectl apply -f argocd/secret_printer_webserver_app.yaml -n argocd --kubeconfig $(KUBECONFIG) || true

# Cleanup resources (e.g., leftover resources after uninstalling)
clean:
	kubectl delete namespace $(NAMESPACE_SECRET_PRINTER) --kubeconfig $(KUBECONFIG) || true
	kubectl delete namespace $(NAMESPACE_ARGOCD) --kubeconfig $(KUBECONFIG) || true
	kubectl delete namespace $(VAULT_NAMESPACE) --kubeconfig $(KUBECONFIG) || true