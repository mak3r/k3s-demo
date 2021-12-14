# K3s demo

## Quickstart

### Build the infrastructure
`make infrastructure`

### Setup a k3s single node install
`make single-node`

### Setup a k3s multi node install
`make multi-node`

### Peek at the multi-node cluster
`kubectl --kubeconfig ./kubeconfig_multi get node`


## Demo
1. `make infrastructure`
1. `make -o infrastructure single-node`
1. `kubectl --kubeconfig ./kubeconfig_single get node`
1. `make -o infrastructure multi-node`
1. `kubectl --kubeconfig ./kubeconfig_multi get node`
1. `terraform -chdir=terraform-setup/ output`
1. `ssh ec2-user@demo1 'cat /etc/rancher/k3s/config.yaml'`
1. `ssh ec2-user@demo2 'cat /etc/rancher/k3s/config.yaml'`
