AUTOMATION_DIR := automation
DEMO_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/demo
DEMO_TF := $(DEMO_TF_DIR)/tf.sh
MANUAL_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/manual-demo
MANUAL_TF := $(MANUAL_TF_DIR)/tf.sh
SINGLE_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/single-rhel9
DEVICE_TF_DIR := $(AUTOMATION_DIR)/terraform/environments/device-vm
DEVICE_TF := $(DEVICE_TF_DIR)/tf.sh
ANSIBLE_DIR := $(AUTOMATION_DIR)/ansible
ANSIBLE_VENV_DIR := $(AUTOMATION_DIR)/.venv
ANSIBLE_REQUIREMENTS := $(AUTOMATION_DIR)/requirements-ansible.txt
ANSIBLE_PLAYBOOK := $(abspath $(ANSIBLE_VENV_DIR))/bin/ansible-playbook
ANSIBLE_PIP := $(ANSIBLE_VENV_DIR)/bin/pip
ANSIBLE_STAMP := $(ANSIBLE_VENV_DIR)/.ansible-ready

.PHONY: help init-files automation-init-files ansible-bootstrap
.PHONY: plan up down configure
.PHONY: rhel-vms-init rhel-vms-plan rhel-vms-up rhel-vms-down
.PHONY: create-rhel9 bootc-build approve-enrollment fleet-apply
.PHONY: device-vm-init device-vm-plan device-vm-up device-vm-down device-demo
.PHONY: tf-init tf-plan tf-up tf-down

help:
	@printf "%s\n" \
	"Supported targets:" \
	"  make help             Show this help" \
	"  make init-files       Seed local gitignored config files" \
	"  make up               Full automation: Terraform + Ansible" \
	"  make down             Tear down full automated stack" \
	"  make plan             Terraform plan for full automated stack" \
	"  make configure        Run only the Ansible configuration phase" \
	"  make rhel-vms-up      Create only the manual-demo RHEL 9 VMs" \
	"  make rhel-vms-down    Destroy only the manual-demo RHEL 9 VMs" \
	"  make create-rhel9     Create one standalone RHEL 9 VM" \
	"  make bootc-build      Build the demo bootc image, push it to Satellite, and fetch the bootable qcow2" \
	"  make device-vm-up     Create one demo device VM from the bootc qcow2 disk image" \
	"  make device-vm-down   Destroy the demo device VM" \
	"  make approve-enrollment Approve pending Edge Manager enrollment requests" \
	"  make fleet-apply      Create or update the demo Edge Manager fleet" \
	"  make device-demo      Build image, create the device VM, approve enrollment, and apply the fleet"

init-files: automation-init-files

automation-init-files:
	$(AUTOMATION_DIR)/scripts/init-files.sh

$(ANSIBLE_STAMP): $(ANSIBLE_REQUIREMENTS)
	command -v python3 >/dev/null 2>&1 || { echo "python3 not found"; exit 1; }
	test -d $(ANSIBLE_VENV_DIR) || python3 -m venv $(ANSIBLE_VENV_DIR)
	$(ANSIBLE_PIP) install --upgrade pip
	$(ANSIBLE_PIP) install -r $(ANSIBLE_REQUIREMENTS)
	touch $(ANSIBLE_STAMP)

ansible-bootstrap: $(ANSIBLE_STAMP)

tf-init: automation-init-files
	cd $(DEMO_TF_DIR) && terraform init -input=false

tf-plan: tf-init
	$(DEMO_TF) plan -input=false

tf-up: tf-init
	cd $(DEMO_TF_DIR) && ./tf.sh apply -auto-approve -input=false

tf-down: tf-init
	$(DEMO_TF) destroy -auto-approve -input=false

rhel-vms-init: automation-init-files
	cd $(MANUAL_TF_DIR) && terraform init -input=false

rhel-vms-plan: rhel-vms-init
	$(MANUAL_TF) plan -input=false

rhel-vms-up: rhel-vms-init
	cd $(MANUAL_TF_DIR) && ./tf.sh apply -auto-approve -input=false

rhel-vms-down: rhel-vms-init
	$(MANUAL_TF) destroy -auto-approve -input=false

device-vm-init: automation-init-files
	cd $(DEVICE_TF_DIR) && terraform init -input=false

device-vm-plan: device-vm-init
	ACTION=plan $(AUTOMATION_DIR)/scripts/device-vm.sh

device-vm-up: device-vm-init
	ACTION=apply $(AUTOMATION_DIR)/scripts/device-vm.sh

device-vm-down: device-vm-init
	ACTION=destroy $(AUTOMATION_DIR)/scripts/device-vm.sh

configure: automation-init-files ansible-bootstrap
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/demo_up.yml

plan: tf-plan

up: tf-up configure

down: tf-down

create-rhel9:
	$(AUTOMATION_DIR)/scripts/create-rhel9.sh

bootc-build: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/bootc-build.sh

approve-enrollment: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/approve-enrollment.sh

fleet-apply: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/fleet-apply.sh

device-demo: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/bootc-build.sh
	ACTION=apply $(AUTOMATION_DIR)/scripts/device-vm.sh
	WAIT_FOR_PENDING=true WAIT_TIMEOUT_SECONDS=1800 $(AUTOMATION_DIR)/scripts/approve-enrollment.sh
	$(AUTOMATION_DIR)/scripts/fleet-apply.sh
