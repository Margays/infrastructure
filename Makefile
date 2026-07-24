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
build-kind:
	kind create cluster --name margays-kind

.PHONY: delete-kind
delete-kind:
	kind delete cluster --name margays-kind

## --------------- ##
#     FluxCD
## --------------- ##

.PHONY: flux
flux:
	helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  		--namespace flux-system \
	    --create-namespace

## --------------- ##
#       E2E
## --------------- ##

.PHONY: bootstrap-kind
bootstrap-kind: build-kind flux

.PHONY: bootstrap
bootstrap: build-nodes build-kubernetes flux
