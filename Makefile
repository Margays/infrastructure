mkfile_dir := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
user := margay
environment := production

ANSIBLE_INVENTORY_DIR := $(mkfile_dir)/inventories/$(environment)/ansible
KUBESPRAY_INVENTORY_DIR := $(mkfile_dir)/inventories/$(environment)/kubespray
ANSIBLE_DIR := $(mkfile_dir)/ansible
KUBESPRAY_DIR := $(mkfile_dir)/kubespray

.ONESHELL:

.PHONY: build-nodes
build-nodes:
	test -d $(ANSIBLE_INVENTORY_DIR)/.venv || python3 -m virtualenv $(ANSIBLE_INVENTORY_DIR)/.venv
	cd $(ANSIBLE_DIR)
	. $(ANSIBLE_INVENTORY_DIR)/.venv/bin/activate
	pip install -r requirements.txt
	mkdir -p collections
	ansible-galaxy collection install -r requirements.yml -p collections
	ansible-playbook -i $(ANSIBLE_INVENTORY_DIR)/hosts.yaml playbooks/main.yml -u $(user) -K --tags "system_upgrade"

k8s_requirements:
	test -d $(KUBESPRAY_INVENTORY_DIR)/.venv || python3 -m virtualenv $(KUBESPRAY_INVENTORY_DIR)/.venv
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	pip install -r $(KUBESPRAY_DIR)/requirements.txt

.PHONY: build-kubernetes
build-kubernetes: k8s_requirements
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	cd $(KUBESPRAY_DIR)
	ansible-playbook -i $(KUBESPRAY_INVENTORY_DIR)/hosts.yaml -u $(user) --become --become-user=root -K cluster.yml

delete-kubernetes: k8s_requirements
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	cd $(KUBESPRAY_DIR)
	ansible-playbook -i $(KUBESPRAY_INVENTORY_DIR)/hosts.yaml -u $(user) --become --become-user=root -K reset.yml