ansible-playbook -i ../inventories/production/bare/hosts.yaml playbooks/main.yml -u margay -K -k



ansible-galaxy collection install -r requirements.yml -p collections