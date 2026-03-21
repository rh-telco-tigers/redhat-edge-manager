AUTOMATION_DIR := automation
DEMO_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/demo
DEMO_TF := $(DEMO_TF_DIR)/tf.sh
MANUAL_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/manual-demo
MANUAL_TF := $(MANUAL_TF_DIR)/tf.sh
SINGLE_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/single-rhel9
ANSIBLE_DIR := $(AUTOMATION_DIR)/ansible

.PHONY: help init-files automation-init-files
.PHONY: plan up down configure
.PHONY: auto-vm-init auto-vm-plan auto-vm-up auto-vm-down
.PHONY: rhel-vms-init rhel-vms-plan rhel-vms-up rhel-vms-down
.PHONY: create-rhel9
.PHONY: tf-init tf-plan tf-up tf-down

help:
	@printf "%s\n" \
	"Supported targets:" \
	"  make help             Show this help" \
	"  make init-files       Seed local gitignored config files" \
	"  make up               Full automation: Terraform + Ansible" \
	"  make down             Tear down full automated stack" \
	"  make plan             Terraform plan for full automated stack" \
	"  make auto-vm-up       Terraform-only layer of the automated stack" \
	"  make auto-vm-down     Destroy Terraform-managed automated-stack VMs" \
	"  make rhel-vms-up      Create only the manual-demo RHEL 9 VMs" \
	"  make rhel-vms-down    Destroy only the manual-demo RHEL 9 VMs" \
	"  make create-rhel9     Create one standalone RHEL 9 VM"

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

rhel-vms-init: automation-init-files
	cd $(MANUAL_TF_DIR) && terraform init -input=false

rhel-vms-plan: rhel-vms-init
	$(MANUAL_TF) plan -input=false

rhel-vms-up: rhel-vms-init
	cd $(MANUAL_TF_DIR) && ./tf.sh apply -auto-approve -input=false

rhel-vms-down: rhel-vms-init
	$(MANUAL_TF) destroy -auto-approve -input=false

configure: automation-init-files
	command -v ansible-playbook >/dev/null 2>&1 || { echo "ansible-playbook not found"; exit 1; }
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/demo_up.yml

plan: auto-vm-plan

up: auto-vm-up configure

down: auto-vm-down

create-rhel9:
	$(AUTOMATION_DIR)/scripts/create-rhel9.sh

tf-init: auto-vm-init

tf-plan: auto-vm-plan

tf-up: auto-vm-up

tf-down: auto-vm-down
