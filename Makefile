ANSIBLE_USER ?= margay
ENVIRONMENT ?= production
PREINSTALL_REQUIREMENTS ?= false

MKFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ANSIBLE_INVENTORY_DIR := $(MKFILE_DIR)/inventories/$(ENVIRONMENT)/ansible
KUBESPRAY_INVENTORY_DIR := $(MKFILE_DIR)/inventories/$(ENVIRONMENT)/kubespray
ANSIBLE_DIR := $(MKFILE_DIR)/ansible
KUBESPRAY_DIR := $(MKFILE_DIR)/kubespray
KIND_DIR := $(MKFILE_DIR)/utils/kind
KIND_CONFIG := $(KIND_DIR)/kind-config.yaml
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

.PHONY: build-kind
build-kind:
	kind create cluster --name kind --config=$(KIND_CONFIG)
	bash $(KIND_DIR)/setup.sh

.PHONY: delete-kind
delete-kind:
	kind delete cluster --name kind

.PHONY: check-env-variables
check-env-variables:
ifndef GITHUB_SSH_PRIVATE_KEY
	$(error GITHUB_SSH_PRIVATE_KEY is undefined)
endif

.PHONY: setup-requirements
setup-requirements:
ifeq ($(PREINSTALL_REQUIREMENTS),true)
    bash $(MKFILE_DIR)/setup_requirements.sh
endif

.PHONY: flux
flux: check-env-variables
	flux bootstrap git \
      --url=ssh://git@github.com/OpenSourceMargays/infrastructure.git \
      --private-key-file=$(GITHUB_SSH_PRIVATE_KEY) \
	  --branch=$(BRANCH) \
      --path=flux/clusters/$(ENVIRONMENT) \
	  --network-policy=false \
	  --silent
	kubectl apply -k flux/clusters/$(ENVIRONMENT)

.PHONY: bootstrap-kind
bootstrap-kind: check-env-variables setup-requirements build-kind flux

.PHONY: bootstrap
bootstrap: build-nodes build-kubernetes flux
