AUTOMATION_DIR := automation
DEMO_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/demo
DEMO_TF := $(DEMO_TF_DIR)/tf.sh
MANUAL_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/manual-demo
MANUAL_TF := $(MANUAL_TF_DIR)/tf.sh
SINGLE_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/single-rhel9
ANSIBLE_DIR := $(AUTOMATION_DIR)/ansible

.PHONY: init-files automation-init-files
.PHONY: plan up down configure
.PHONY: auto-vm-init auto-vm-plan auto-vm-up auto-vm-down
.PHONY: demo-vm-init demo-vm-plan demo-vm-up demo-vm-down
.PHONY: manual-demo-vm-init manual-demo-vm-plan manual-demo-vm-up manual-demo-vm-down
.PHONY: create-rhel9
.PHONY: tf-init tf-plan tf-up tf-down

init-files: automation-init-files

automation-init-files:
	$(AUTOMATION_DIR)/scripts/init-files.sh

auto-vm-init: automation-init-files
	cd $(DEMO_TF_DIR) && terraform init -input=false

auto-vm-plan: auto-vm-init
	$(DEMO_TF) plan -input=false

auto-vm-up: auto-vm-init
	cd $(DEMO_TF_DIR) && ./tf.sh apply -auto-approve -input=false

auto-vm-down: auto-vm-init
	$(DEMO_TF) destroy -auto-approve -input=false

manual-demo-vm-init: automation-init-files
	cd $(MANUAL_TF_DIR) && terraform init -input=false

manual-demo-vm-plan: manual-demo-vm-init
	$(MANUAL_TF) plan -input=false

manual-demo-vm-up: manual-demo-vm-init
	cd $(MANUAL_TF_DIR) && ./tf.sh apply -auto-approve -input=false

manual-demo-vm-down: manual-demo-vm-init
	$(MANUAL_TF) destroy -auto-approve -input=false

configure: automation-init-files
	command -v ansible-playbook >/dev/null 2>&1 || { echo "ansible-playbook not found"; exit 1; }
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/demo_up.yml

plan: auto-vm-plan

up: auto-vm-up configure

down: auto-vm-down

create-rhel9:
	$(AUTOMATION_DIR)/scripts/create-rhel9.sh

# Backward-compatible Terraform aliases while the docs move to automation/.
demo-vm-init: auto-vm-init

demo-vm-plan: auto-vm-plan

demo-vm-up: auto-vm-up

demo-vm-down: auto-vm-down

tf-init: auto-vm-init

tf-plan: auto-vm-plan

tf-up: auto-vm-up

tf-down: auto-vm-down
