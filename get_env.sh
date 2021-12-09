#!/usr/bin/env bash

$(terraform output -state=terraform-setup/terraform.tfstate -json arm_node_ips | jq -r 'keys[] as $k | "export IP\($k)=\(.[$k])"')

export MULTI_NAME=$(terraform output -state=terraform-setup/terraform.tfstate -json multi_name | sed 's/"//g')
export SINGLE_NAME=$(terraform output -state=terraform-setup/terraform.tfstate -json single_name | sed 's/"//g')
