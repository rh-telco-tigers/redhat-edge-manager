AUTOMATION_DIR := automation
DEMO_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/demo
DEMO_TF := $(DEMO_TF_DIR)/tf.sh
SINGLE_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/single-rhel9
ANSIBLE_DIR := $(AUTOMATION_DIR)/ansible

.PHONY: init-files automation-init-files
.PHONY: plan up down configure
.PHONY: demo-vm-init demo-vm-plan demo-vm-up demo-vm-down
.PHONY: create-rhel9
.PHONY: tf-init tf-plan tf-up tf-down

init-files: automation-init-files

automation-init-files:
	$(AUTOMATION_DIR)/scripts/init-files.sh

demo-vm-init: automation-init-files
	cd $(DEMO_TF_DIR) && terraform init -input=false

demo-vm-plan: demo-vm-init
	$(DEMO_TF) plan -input=false

demo-vm-up: demo-vm-init
	cd $(DEMO_TF_DIR) && ./tf.sh apply -auto-approve -input=false

demo-vm-down: demo-vm-init
	$(DEMO_TF) destroy -auto-approve -input=false

configure: automation-init-files
	command -v ansible-playbook >/dev/null 2>&1 || { echo "ansible-playbook not found"; exit 1; }
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/demo_up.yml

plan: demo-vm-plan

up: demo-vm-up configure

down: demo-vm-down

create-rhel9:
	$(AUTOMATION_DIR)/scripts/create-rhel9.sh

# Backward-compatible Terraform aliases while the docs move to automation/.
tf-init: demo-vm-init

tf-plan: demo-vm-plan

tf-up: demo-vm-up

tf-down: demo-vm-down
