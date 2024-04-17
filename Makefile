ANSIBLE_USER ?= margay
ENVIRONMENT ?= kind

MKFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ANSIBLE_INVENTORY_DIR := $(MKFILE_DIR)/inventories/$(ENVIRONMENT)/ansible
KUBESPRAY_INVENTORY_DIR := $(MKFILE_DIR)/inventories/$(ENVIRONMENT)/kubespray
ANSIBLE_DIR := $(MKFILE_DIR)/ansible
KUBESPRAY_DIR := $(MKFILE_DIR)/kubespray
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

.ONESHELL:

.PHONY: ansible-requirements
ansible-requirements:
	test -d $(ANSIBLE_INVENTORY_DIR)/.venv || python3 -m virtualenv $(ANSIBLE_INVENTORY_DIR)/.venv
	. $(ANSIBLE_INVENTORY_DIR)/.venv/bin/activate
	pip install -r $(ANSIBLE_DIR)/requirements.txt
	mkdir -p $(ANSIBLE_DIR)/collections
	ansible-galaxy collection install -r $(ANSIBLE_DIR)/requirements.yml -p $(ANSIBLE_DIR)/collections

## --------------- ##
#     Proxmox
## --------------- ##

.PHONY: provision-proxmox
provision-proxmox: ansible-requirements
	cd $(ANSIBLE_DIR)
	. $(ANSIBLE_INVENTORY_DIR)/.venv/bin/activate
	ansible-playbook -i $(ANSIBLE_INVENTORY_DIR)/hosts.yaml playbooks/proxmox/provision.yml -u $(ANSIBLE_USER) -K

.PHONY: build-nodes
build-nodes: ansible-requirements
	cd $(ANSIBLE_DIR)
	. $(ANSIBLE_INVENTORY_DIR)/.venv/bin/activate
	ansible-galaxy collection install -r requirements.yml -p collections
	ansible-playbook -i $(ANSIBLE_INVENTORY_DIR)/hosts.yaml playbooks/k8s_nodes/provision.yml -u $(ANSIBLE_USER) -K

## --------------- ##
#       Kind
## --------------- ##

.PHONY: build-kind
build-kind: ansible-requirements
	cd $(ANSIBLE_DIR)
	. $(ANSIBLE_INVENTORY_DIR)/.venv/bin/activate
	ansible-playbook -i $(ANSIBLE_INVENTORY_DIR)/hosts.yaml playbooks/kind/cluster.yaml -u $(ANSIBLE_USER) -K

.PHONY: delete-kind
delete-kind:
	kind delete cluster --name margays-kind

## --------------- ##
#     Kubespray
## --------------- ##
.PHONY: kubespray-requirements
kubespray-requirements:
	test -d $(KUBESPRAY_INVENTORY_DIR)/.venv || python3.11 -m virtualenv $(KUBESPRAY_INVENTORY_DIR)/.venv
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	git submodule update --init --recursive
	pip install -r $(KUBESPRAY_DIR)/requirements.txt

.PHONY: build-kubernetes
build-kubernetes: kubespray-requirements
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	cd $(KUBESPRAY_DIR)
	ansible-playbook -i $(KUBESPRAY_INVENTORY_DIR)/hosts.yaml -u $(ANSIBLE_USER) --become --become-user=root -K cluster.yml
	bash $(KUBESPRAY_INVENTORY_DIR)/artifacts/kubectl.sh $(KUBESPRAY_INVENTORY_DIR)/artifacts/admin.conf

.PHONY: delete-kubernetes
delete-kubernetes: kubespray-requirements
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	cd $(KUBESPRAY_DIR)
	ansible-playbook -i $(KUBESPRAY_INVENTORY_DIR)/hosts.yaml -u $(ANSIBLE_USER) --become --become-user=root -K reset.yml

## --------------- ##
#     FluxCD
## --------------- ##

.PHONY: check-env-variables
check-env-variables:
ifndef GITHUB_SSH_PRIVATE_KEY
	$(error GITHUB_SSH_PRIVATE_KEY is undefined)
endif

.PHONY: flux
flux: ansible-requirements
	cd $(ANSIBLE_DIR)
	. $(ANSIBLE_INVENTORY_DIR)/.venv/bin/activate
	ansible-playbook -i $(ANSIBLE_INVENTORY_DIR)/hosts.yaml playbooks/kuberentes/post_cluster_setup.yml -u $(ANSIBLE_USER) -K

## --------------- ##
#       E2E
## --------------- ##

.PHONY: bootstrap-kind
bootstrap-kind: check-env-variables build-kind flux

.PHONY: bootstrap
bootstrap: check-env-variables build-nodes build-kubernetes flux
