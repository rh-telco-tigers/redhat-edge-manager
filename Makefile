# Proxmox / RHEL VM — credentials: export PROXMOX_VE_* or use prereqs/terraform/.env
TF_DIR := prereqs/terraform
TF := $(TF_DIR)/tf.sh

# Keycloak integration VM + automation
KC_TF_DIR := labs/02-keycloak-integration/terraform
KC_TF := $(KC_TF_DIR)/tf.sh
KC_ANSIBLE_DIR := labs/02-keycloak-integration/ansible

.PHONY: tf-init tf-plan tf-up tf-down
.PHONY: rhem-vm-init rhem-vm-plan rhem-vm-up rhem-vm-down
.PHONY: keycloak-init-files keycloak-vm-init keycloak-vm-plan keycloak-vm-up keycloak-vm-down
.PHONY: keycloak-configure keycloak-setup

tf-init:
	cd $(TF_DIR) && terraform init -input=false

tf-plan:
	$(TF) plan -input=false

tf-up:
	cd $(TF_DIR) && terraform init -input=false && ./tf.sh apply -auto-approve -input=false

tf-down:
	$(TF) destroy -auto-approve -input=false

rhem-vm-init: tf-init

rhem-vm-plan: tf-plan

rhem-vm-up: tf-up

rhem-vm-down: tf-down

keycloak-init-files:
	test -f $(KC_TF_DIR)/.env || cp $(KC_TF_DIR)/.env.example $(KC_TF_DIR)/.env
	test -f $(KC_TF_DIR)/terraform.tfvars || cp $(KC_TF_DIR)/terraform.tfvars.example $(KC_TF_DIR)/terraform.tfvars
	test -f $(KC_ANSIBLE_DIR)/inventory/hosts.yml || cp $(KC_ANSIBLE_DIR)/inventory/hosts.yml.example $(KC_ANSIBLE_DIR)/inventory/hosts.yml
	test -f $(KC_ANSIBLE_DIR)/group_vars/all.yml || cp $(KC_ANSIBLE_DIR)/group_vars/all.yml.example $(KC_ANSIBLE_DIR)/group_vars/all.yml

keycloak-vm-init:
	cd $(KC_TF_DIR) && terraform init -input=false

keycloak-vm-plan:
	$(KC_TF) plan -input=false

keycloak-vm-up:
	cd $(KC_TF_DIR) && terraform init -input=false && ./tf.sh apply -auto-approve -input=false

keycloak-vm-down:
	$(KC_TF) destroy -auto-approve -input=false

keycloak-configure:
	command -v ansible-playbook >/dev/null 2>&1 || { echo "ansible-playbook not found"; exit 1; }
	cd $(KC_ANSIBLE_DIR) && ansible-playbook playbooks/keycloak_integration.yml

keycloak-setup:
	$(MAKE) keycloak-vm-up
	$(MAKE) keycloak-configure
