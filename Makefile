SHELL := /bin/bash

K3S_CHANNEL := v1.21
TOKEN := kaK390.^KAJkf3yrtK
export KUBECONFIG := kubeconfig

.PHONY: destroy
destroy:
	-rm kubeconfig_single kubeconfig_multi kubeconfig_all 
	cd terraform-setup && terraform destroy -auto-approve && rm terraform.tfstate terraform.tfstate.backup

.PHONY: all
all: infrastructure single-node multi-node kubeconfig

.PHONY: infrastructure
infrastructure:
	echo "Creating infrastructure"
	cd terraform-setup && terraform init && terraform apply -auto-approve

.PHONY: single-node
single-node: infrastructure
	#Install k3s on the node
	## Get the first IP address
	source get_env.sh && echo $${IP0}
	## Install k3s
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP0} "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $${IP0}' INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) K3S_KUBECONFIG_MODE=644 sh -"
	## Get the kubeconfig
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP0}:/etc/rancher/k3s/k3s.yaml kubeconfig_single
	## update the kubeconfig to use the public IP address
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP0}/g" kubeconfig_single

.PHONY: multi-node
multi-node: infrastructure
	# Install k3s on multiple nodes
	## Set the configuration file for node 1/3
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP1} 'sudo mkdir -p /etc/rancher/k3s'
	source get_env.sh && sed 's/{node}/01/' config/config.yaml.template | sed "/^server/d" | sed 's/{token}/$(TOKEN)/' | sed "s/{tls-san1}/$${MULTI_NAME}/" | sed "s/{tls-san2}/$${IP1}/" | ssh -o StrictHostKeyChecking=no ubuntu@$${IP1} 'cat > ./config.yaml && sudo mv ./config.yaml /etc/rancher/k3s/config.yaml'
	## Install k3s on node 1/3
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP1} "curl -sfL https://get.k3s.io | K3S_CLUSTER_INIT=true INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) sh -"
	## Get the kubeconfig for the multi node cluster
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP1}:/etc/rancher/k3s/k3s.yaml kubeconfig_multi
	## update the kubeconfig to use the public IP address
	source get_env.sh && sed -i '' "s/127.0.0.1/$${IP1}/g" kubeconfig_multi

	## Set the configuration file for node 2/3
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP2} 'sudo mkdir -p /etc/rancher/k3s'
	export CA_TOKEN=$$(source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP1} 'sudo cat /var/lib/rancher/k3s/server/node-token') && source get_env.sh && sed 's/{node}/02/' config/config.yaml.template | sed "s/{server}/$${IP1}/" | sed "s/{token}/$${CA_TOKEN}/" | sed "s/{tls-san1}/$${MULTI_NAME}/" | sed "s/{tls-san2}/$${IP2}/" | ssh -o StrictHostKeyChecking=no ubuntu@$${IP2} 'cat > ./config.yaml && sudo mv ./config.yaml /etc/rancher/k3s/config.yaml'
	## Install k3s on node 2/3
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP2} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) sh -"

	## Set the configuration file for node 3/3
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP3} 'sudo mkdir -p /etc/rancher/k3s'
	export CA_TOKEN=$$(source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP1} 'sudo cat /var/lib/rancher/k3s/server/node-token') && source get_env.sh && sed 's/{node}/03/' config/config.yaml.template | sed "s/{server}/$${IP1}/" | sed "s/{token}/$${CA_TOKEN}/" | sed "s/{tls-san1}/$${MULTI_NAME}/" | sed "s/{tls-san2}/$${IP3}/" | ssh -o StrictHostKeyChecking=no ubuntu@$${IP3} 'cat > ./config.yaml && sudo mv ./config.yaml /etc/rancher/k3s/config.yaml'
	## Install k3s on node 3/3
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP3} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) sh -"

kubeconfig: multi-node single-node
	sed -i "" 's/default/k3s-single/g' ./kubeconfig_single
	sed -i "" 's/default/k3s-multi/g' ./kubeconfig_multi
	KUBECONFIG=./kubeconfig_single:./kubeconfig_multi kubectl config view --flatten > ./kubeconfig_all 
	chmod 600 ./kubeconfig_all
