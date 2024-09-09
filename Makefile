# Secret Printer Webserver
CHART_NAME=secret-printer-webserver
NAMESPACE_SECRET_PRINTER=secret-printer-webserver
NAMESPACE_ARGOCD=argocd
CHART_DIR=./secret_printer_webserver
RELEASE_NAME=secret-printer-webserver
KUBECONFIG=~/.kube/config
# Vault
VAULT_NAMESPACE=vault
VAULT_RELEASE_NAME=vault
VAULT_VERSION=0.25.0 # You can change this to a specific Vault version if necessary
KUBECONFIG=~/.kube/config

# Default target: shows usage information
.PHONY: help
help:
	@echo "Makefile targets:"
	@echo "  install   - Install the Helm chart"
	@echo "  upgrade   - Upgrade the Helm chart"
	@echo "  uninstall - Uninstall the Helm chart"
	@echo "  lint      - Lint the Helm chart"
	@echo "  template  - Render chart templates"
	@echo "  install-vault   - Install HashiCorp Vault with Helm"
	@echo "  uninstall-vault - Uninstall HashiCorp Vault"
	@echo "  clean     - Cleanup resources"


# Install the Helm chart
.PHONY: install
install: lint
	helm upgrade --install $(RELEASE_NAME) $(CHART_DIR) --namespace $(NAMESPACE_SECRET_PRINTER) --kubeconfig $(KUBECONFIG) --create-namespace

# Upgrade the Helm chart (if it's already installed)
.PHONY: upgrade
upgrade:
	helm upgrade --install $(RELEASE_NAME) $(CHART_DIR) --namespace $(NAMESPACE_SECRET_PRINTER) --kubeconfig $(KUBECONFIG) --create-namespace

# Uninstall the Helm chart
.PHONY: uninstall
uninstall:
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE_SECRET_PRINTER) --kubeconfig $(KUBECONFIG)

# Lint the Helm chart (to check for common issues)
.PHONY: lint
lint:
	helm lint $(CHART_DIR)

# Render chart templates (to check what will be deployed)
.PHONY: template
template:
	helm template $(RELEASE_NAME) $(CHART_DIR) --namespace $(NAMESPACE_SECRET_PRINTER) --kubeconfig $(KUBECONFIG)

# Installs ArgoCD 7.5.2
.PHONY: install_argo
install_argo:
	helm dependency build argocd
	helm upgrade --install argocd argocd --namespace $(NAMESPACE_ARGOCD) --values argocd/values.yaml --create-namespace

# Uninstalls ArgoCD 7.5.2
.PHONY: uninstall_argo
uninstall_argo:
	helm dependency build argocd
	helm uninstall argocd argocd --namespace $(NAMESPACE_ARGOCD)

# Add HashiCorp Helm repository (if not already added) and update it
.PHONY: add-hashicorp-repo
add-hashicorp-repo:
	helm repo add hashicorp https://helm.releases.hashicorp.com || true
	helm repo update

# Install HashiCorp Vault with Helm
.PHONY: install-vault
install-vault: add-hashicorp-repo
	helm upgrade --install $(VAULT_RELEASE_NAME) hashicorp/vault --version $(VAULT_VERSION) --namespace $(VAULT_NAMESPACE) --kubeconfig $(KUBECONFIG) --create-namespace --set "server.dev.enabled=true"

# Uninstall HashiCorp Vault
.PHONY: uninstall-vault
uninstall-vault:
	helm uninstall $(VAULT_RELEASE_NAME) --namespace $(VAULT_NAMESPACE) --kubeconfig $(KUBECONFIG)

# Cleanup resources (e.g., leftover resources after uninstalling)
.PHONY: clean
clean:
	kubectl delete namespace $(NAMESPACE_SECRET_PRINTER) --kubeconfig $(KUBECONFIG) || true
	kubectl delete namespace $(NAMESPACE_ARGOCD) --kubeconfig $(KUBECONFIG) || true
	kubectl delete namespace $(VAULT_NAMESPACE) --kubeconfig $(KUBECONFIG) || true


