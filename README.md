# Vault as Central Secret Store in GitOps


## Get Started 
### Prerequisites:

* helm installed
* kubectl installed
* k3d installed
* vault cli installed

### Create local PoC
1. Create local k3d cluster
```bash
k3d cluster create mycluster
```
2. Install everything
```bash
make install-all
```