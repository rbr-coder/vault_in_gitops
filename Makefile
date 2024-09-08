# Variables
CHART_NAME=secret-printer-webserver
NAMESPACE=secret-printer-webserver
CHART_DIR=./secret_printer_webserver
RELEASE_NAME=secret-printer-webserver
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
	@echo "  clean     - Cleanup resources"

# Install the Helm chart
.PHONY: install
install: lint

	helm upgrade --install $(RELEASE_NAME) $(CHART_DIR) --namespace $(NAMESPACE) --kubeconfig $(KUBECONFIG) --create-namespace

# Upgrade the Helm chart (if it's already installed)
.PHONY: upgrade
upgrade:
	helm upgrade --install $(RELEASE_NAME) $(CHART_DIR) --namespace $(NAMESPACE) --kubeconfig $(KUBECONFIG) --create-namespace

# Uninstall the Helm chart
.PHONY: uninstall
uninstall:
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE) --kubeconfig $(KUBECONFIG)

# Lint the Helm chart (to check for common issues)
.PHONY: lint
lint:
	helm lint $(CHART_DIR)

# Render chart templates (to check what will be deployed)
.PHONY: template
template:
	helm template $(RELEASE_NAME) $(CHART_DIR) --namespace $(NAMESPACE) --kubeconfig $(KUBECONFIG)

# Cleanup resources (e.g., leftover resources after uninstalling)
.PHONY: clean
clean:
	kubectl delete namespace $(NAMESPACE) --kubeconfig $(KUBECONFIG) || true
