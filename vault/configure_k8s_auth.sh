#!/bin/bash

# Set Vault address and token
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=root

# Port forwarding in a separate terminal window (ensure the port is forwarded properly)
kubectl port-forward -n vault vault-0 8200 &

# Wait a few seconds to ensure port forwarding is established
sleep 5

# Enable kv-v2 engine in Vault (check if already enabled to avoid errors)
vault secrets list | grep 'kv-v2/' || vault secrets enable -path=kv-v2 kv-v2

# Create kv-v2 secret with two keys
vault kv put kv-v2/secret_printer_webserver user="secret_user" password="secret_password"

# Create policy to enable reading the above secret
vault policy write secret_printer_webserver - <<EOF
path "kv-v2/data/secret_printer_webserver" {
  capabilities = ["read"]
}
EOF

# Enable Kubernetes Auth Method (check if already enabled)
vault auth list | grep 'kubernetes/' || vault auth enable kubernetes

# Switch Namespace to vault (ensure namespace exists)
kubectl config set-context --current --namespace=vault

# Get Kubernetes host address
K8S_HOST="https://$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}'):443"

# Get Service Account token from Vault Pod
SA_TOKEN=$(kubectl exec vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Get Service Account CA certificate from Vault Pod
SA_CERT=$(kubectl exec vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)

# Configure Kubernetes Auth Method in Vault
vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$SA_CERT"

# Create authenticate Role for ArgoCD
vault write auth/kubernetes/role/argocd \
  bound_service_account_names=argocd-repo-server \
  bound_service_account_namespaces=argocd \
  policies=secret_printer_webserver \
  ttl=48h