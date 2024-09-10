# Variables
NAMESPACE_SECRET_PRINTER = webserver
NAMESPACE_ARGOCD = argocd
KUBECONFIG = $(HOME)/.kube/config
VAULT_NAMESPACE = vault
VAULT_RELEASE_NAME = vault
VAULT_VERSION = 0.25.0 # Adjust to desired Vault version
ARGOCD_VERSION = 7.5.2 # Adjust to desired ArgoCD version

# Common Helm options
HELM_OPTS = --kubeconfig $(KUBECONFIG) --create-namespace

.PHONY: help install-argo uninstall-argo add-hashicorp-repo install-vault configure-vault uninstall-vault apply-webserver-app install-all clean

# Default target: shows usage information
help:
	@echo "Available targets:"
	@echo "  install-argo       - Install ArgoCD $(ARGOCD_VERSION)"
	@echo "  uninstall-argo     - Uninstall ArgoCD"
	@echo "  install-vault      - Install HashiCorp Vault $(VAULT_VERSION)"
	@echo "  uninstall-vault    - Uninstall HashiCorp Vault"
	@echo "  configure-vault    - Configure Vault with Kubernetes auth"
	@echo "  apply-webserver-app - Create ArgoCD Application for the Webserver"
	@echo "  install-all        - Install everything: ArgoCD, Vault, configure and apply webserver app"
	@echo "  clean              - Cleanup resources (Vault, ArgoCD, namespaces)"

# Install ArgoCD with Helm
install-argo:
	@echo "Installing ArgoCD $(ARGOCD_VERSION)..."
	helm dependency build argocd
	helm upgrade --install argocd argocd --namespace $(NAMESPACE_ARGOCD) --values argocd/values.yaml $(HELM_OPTS)

# Uninstall ArgoCD
uninstall-argo:
	@echo "Uninstalling ArgoCD..."
	helm uninstall argocd --namespace $(NAMESPACE_ARGOCD)

# Add HashiCorp Helm repository (if not already added) and update it
add-hashicorp-repo:
	@echo "Adding and updating HashiCorp Helm repository..."
	helm repo add hashicorp https://helm.releases.hashicorp.com || true
	helm repo update

# Install HashiCorp Vault using Helm
install-vault: add-hashicorp-repo
	@echo "Installing Vault $(VAULT_VERSION)..."
	helm upgrade --install $(VAULT_RELEASE_NAME) hashicorp/vault --version $(VAULT_VERSION) \
	--namespace $(VAULT_NAMESPACE) $(HELM_OPTS) --set "server.dev.enabled=true"

# Configure Vault with Kubernetes authentication
configure-vault:
	@echo "Configuring Vault..."
	chmod +x vault/configure_k8s_auth.sh
	vault/configure_k8s_auth.sh

# Uninstall HashiCorp Vault
uninstall-vault:
	@echo "Uninstalling Vault..."
	helm uninstall $(VAULT_RELEASE_NAME) --namespace $(VAULT_NAMESPACE)

# Create ArgoCD Application for the Webserver
apply-webserver-app:
	@echo "Applying ArgoCD Webserver application..."
	kubectl apply -f argocd/secret_printer_webserver_app.yaml -n $(NAMESPACE_ARGOCD) --kubeconfig $(KUBECONFIG)

# Install everything: Vault, ArgoCD, Vault configuration, and Webserver app
install-all: install-vault install-argo configure-vault apply-webserver-app

# Cleanup resources: Vault, ArgoCD, namespaces
clean: uninstall-vault uninstall-argo
	@echo "Cleaning up namespaces and resources..."
	kubectl delete namespace $(NAMESPACE_SECRET_PRINTER) --kubeconfig $(KUBECONFIG) || true
	kubectl delete namespace $(NAMESPACE_ARGOCD) --kubeconfig $(KUBECONFIG) || true
	kubectl delete namespace $(VAULT_NAMESPACE) --kubeconfig $(KUBECONFIG) || true