#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=root

# port forwarding in separate terminal window
kubectl port-forward -n vault vault-0 8200 &

# enable kv-v2 engine in Vault
vault secrets enable kv-v2

# create kv-v2 secret with two keys
vault kv put kv-v2/secret_printer_webserver user="secret_user" password="secret_password"

# create policy to enable reading above secret
vault policy write secret_printer_webserver - <<EOF
path "kv-v2/data/secret_printer_webserver" {
  capabilities = ["read"]
}
EOF

# enable Kubernetes Auth Method
vault auth enable kubernetes

# switch Namespace to vault
kubectl config set-context --current --namespace=vault

# get Kubernetes host address
export K8S_HOST="https://$( kubectl exec vault-0 -- env | grep KUBERNETES_PORT_443_TCP_ADDR| cut -f2 -d'='):443"

# get Service Account token from Vault Pod
export SA_TOKEN=$(kubectl exec vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# get Service Account CA certificate from Vault Pod
export SA_CERT=$(kubectl exec vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)

# configure Kubernetes Auth Method
vault write auth/kubernetes/config \
    token_reviewer_jwt=$SA_TOKEN \
    kubernetes_host=$K8S_HOST \
    kubernetes_ca_cert=$SA_CERT

# create authenticate Role for ArgoCD
vault write auth/kubernetes/role/argocd \
  bound_service_account_names=argocd-repo-server \
  bound_service_account_namespaces=argocd \
  policies=secret_printer_webserver \
  ttl=48h