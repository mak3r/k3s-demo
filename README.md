# K3s demo

## Build the infrastructure
`make infrastructure`

## Setup a k3s single node install
`make single-node`

## Setup a k3s multi node install
`make multi-node`

## Peek at the multi-node cluster
`kubectl --kubeconfig ./kubeconfig_multi get node`