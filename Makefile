ANSIBLE_USER ?= margay
ENVIRONMENT ?= production

MKFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ANSIBLE_INVENTORY_DIR := $(MKFILE_DIR)/inventories/$(ENVIRONMENT)/ansible
KUBESPRAY_INVENTORY_DIR := $(MKFILE_DIR)/inventories/$(ENVIRONMENT)/kubespray
ANSIBLE_DIR := $(MKFILE_DIR)/ansible
KUBESPRAY_DIR := $(MKFILE_DIR)/kubespray
KIND_CONFIG := $(MKFILE_DIR)/kind-config.yaml
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

.ONESHELL:

.PHONY: build-nodes
build-nodes:
	test -d $(ANSIBLE_INVENTORY_DIR)/.venv || python3 -m virtualenv $(ANSIBLE_INVENTORY_DIR)/.venv
	cd $(ANSIBLE_DIR)
	. $(ANSIBLE_INVENTORY_DIR)/.venv/bin/activate
	pip install -r requirements.txt
	mkdir -p collections
	ansible-galaxy collection install -r requirements.yml -p collections
	ansible-playbook -i $(ANSIBLE_INVENTORY_DIR)/hosts.yaml playbooks/main.yml -u $(ANSIBLE_USER) -K

.PHONY: k8s-requirements
k8s-requirements:
	test -d $(KUBESPRAY_INVENTORY_DIR)/.venv || python3.11 -m virtualenv $(KUBESPRAY_INVENTORY_DIR)/.venv
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	pip install -r $(KUBESPRAY_DIR)/requirements.txt

.PHONY: build-kubernetes
build-kubernetes: k8s-requirements
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	cd $(KUBESPRAY_DIR)
	ansible-playbook -i $(KUBESPRAY_INVENTORY_DIR)/hosts.yaml -u $(ANSIBLE_USER) --become --become-user=root -K cluster.yml

.PHONY: delete-kubernetes
delete-kubernetes: k8s-requirements
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	cd $(KUBESPRAY_DIR)
	ansible-playbook -i $(KUBESPRAY_INVENTORY_DIR)/hosts.yaml -u $(ANSIBLE_USER) --become --become-user=root -K reset.yml

build-kind:
	kind create cluster --name kind --config=$(KIND_CONFIG)

delete-kind:
	kind delete cluster --name kind

.PHONY: flux
flux:
ifndef GITHUB_USERNAME
	$(error GITHUB_USERNAME is undefined)
endif
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN is undefined)
endif
	flux bootstrap git \
      --url=https://github.com/OpenSourceMargays/infrastructure.git \
	  --token-auth=true \
      --username=$(GITHUB_USERNAME) \
      --password=$(GITHUB_TOKEN) \
	  --branch=$(BRANCH) \
      --path=flux/clusters/$(ENVIRONMENT)
	kubectl apply -k flux/clusters/$(ENVIRONMENT)

.PHONY: bootstrap
bootstrap: build-nodes build-kubernetes flux
