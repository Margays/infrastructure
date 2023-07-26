mkfile_dir := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
user := margay
environment := production

ANSIBLE_INVENTORY_DIR := $(mkfile_dir)/inventories/$(environment)/ansible
KUBESPRAY_INVENTORY_DIR := $(mkfile_dir)/inventories/$(environment)/kubespray

.ONESHELL:

.PHONY: build-nodes
build-nodes:
	test -d test -d $(ANSIBLE_INVENTORY_DIR)/.venv || python3 -m virtualenv $(ANSIBLE_INVENTORY_DIR)/.venv
	cd $(mkfile_dir)/ansible
	. $(ANSIBLE_INVENTORY_DIR)/.venv/bin/activate
	pip install -r requirements.txt
	mkdir -p collections
	ansible-galaxy collection install -r requirements.yml -p collections
	ansible-playbook -i $(ANSIBLE_INVENTORY_DIR)/hosts.yaml playbooks/main.yml -u $(user) -K

.PHONY: build-kubernetes
build-kubernetes:
	test -d test -d $(KUBESPRAY_INVENTORY_DIR)/.venv || python3 -m virtualenv $(KUBESPRAY_INVENTORY_DIR)/.venv
	cd $(mkfile_dir)/kubespray
	. $(KUBESPRAY_INVENTORY_DIR)/.venv/bin/activate
	ansible-playbook -i $(KUBESPRAY_INVENTORY_DIR)/hosts.yaml -u $(user) --become --become-user=root -K cluster.yml
