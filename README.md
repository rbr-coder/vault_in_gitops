# Vault as Central Secret Store in GitOps

## Prerequisites

* helm installed
* kubectl installed
* k3d installed
* vault cli installed

## Get Started

1. Create local k3d cluster
```bash
k3d cluster create mycluster
```
2. Install everything
```bash
make install-all
```