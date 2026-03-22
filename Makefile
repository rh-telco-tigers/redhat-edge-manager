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
empty :=
space := $(empty) $(empty)
comma := ,
DEVICE_RESERVED_CLI_VARS := name site tags DEVICE_NAME DEVICE_SITE DEVICE_LABEL_KVS BOOTC_QCOW2_PATH UPLOADED_QCOW2_FILE_NAME VM_ID vm_id VM_NAME vm_name VM_DESCRIPTION VM_CORES VM_MEMORY_MB VM_DISK_GB VM_TAGS ACTION WAIT_FOR_PENDING WAIT_TIMEOUT_SECONDS WAIT_POLL_INTERVAL_SECONDS
COMMAND_LINE_VARS := $(sort $(foreach v,$(.VARIABLES),$(if $(filter command line,$(origin $(v))),$(v))))
DEVICE_LABEL_KVS_VALUE := $(strip $(foreach v,$(COMMAND_LINE_VARS),$(if $(filter-out $(DEVICE_RESERVED_CLI_VARS),$(v)),$(v)=$($(v)))))

.PHONY: help init-files automation-init-files ansible-bootstrap
.PHONY: plan up down configure
.PHONY: rhel-vms-init rhel-vms-plan rhel-vms-up rhel-vms-down
.PHONY: create-rhel9 aap-install aap-integrate aap-setup bootc-build approve-enrollment fleet-apply
.PHONY: app-build app-deploy app-demo
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
	"  make aap-install      Install Ansible Automation Platform on the AAP host" \
	"  make aap-integrate    Configure Edge Manager to use AAP authentication" \
	"  make aap-setup        Run both AAP install and AAP integration" \
	"  make bootc-build      Build the demo bootc image, push it to Satellite, and fetch the bootable qcow2" \
	"  make device-vm-up     Create one named demo device VM; pass name=<device> site=<site> env=lab" \
	"  make device-vm-down   Destroy one named demo device VM; pass name=<device>" \
	"  make approve-enrollment Approve pending requests; pass name=<device> to reuse stored labels" \
	"  make fleet-apply      Create or update the demo Edge Manager fleet" \
	"  make device-demo      Build image, create the device VM, approve enrollment, and apply the fleet" \
	"  make app-build        Build the demo application runtime and package images and push them to Satellite" \
	"  make app-deploy       Update the demo fleet to deploy the demo application through Edge Manager" \
	"  make app-demo         Build and deploy the demo application after Labs 3 to 5 are complete"

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
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	BOOTC_QCOW2_PATH='$(BOOTC_QCOW2_PATH)' \
	UPLOADED_QCOW2_FILE_NAME='$(UPLOADED_QCOW2_FILE_NAME)' \
	VM_ID='$(or $(VM_ID),$(vm_id))' \
	VM_NAME='$(or $(VM_NAME),$(vm_name))' \
	VM_DESCRIPTION='$(VM_DESCRIPTION)' \
	VM_CORES='$(VM_CORES)' \
	VM_MEMORY_MB='$(VM_MEMORY_MB)' \
	VM_DISK_GB='$(VM_DISK_GB)' \
	VM_TAGS='$(or $(VM_TAGS),$(tags))' \
	ACTION=plan $(AUTOMATION_DIR)/scripts/device-vm.sh

device-vm-up: device-vm-init
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	BOOTC_QCOW2_PATH='$(BOOTC_QCOW2_PATH)' \
	UPLOADED_QCOW2_FILE_NAME='$(UPLOADED_QCOW2_FILE_NAME)' \
	VM_ID='$(or $(VM_ID),$(vm_id))' \
	VM_NAME='$(or $(VM_NAME),$(vm_name))' \
	VM_DESCRIPTION='$(VM_DESCRIPTION)' \
	VM_CORES='$(VM_CORES)' \
	VM_MEMORY_MB='$(VM_MEMORY_MB)' \
	VM_DISK_GB='$(VM_DISK_GB)' \
	VM_TAGS='$(or $(VM_TAGS),$(tags))' \
	ACTION=apply $(AUTOMATION_DIR)/scripts/device-vm.sh

device-vm-down: device-vm-init
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	BOOTC_QCOW2_PATH='$(BOOTC_QCOW2_PATH)' \
	UPLOADED_QCOW2_FILE_NAME='$(UPLOADED_QCOW2_FILE_NAME)' \
	VM_ID='$(or $(VM_ID),$(vm_id))' \
	VM_NAME='$(or $(VM_NAME),$(vm_name))' \
	VM_DESCRIPTION='$(VM_DESCRIPTION)' \
	VM_CORES='$(VM_CORES)' \
	VM_MEMORY_MB='$(VM_MEMORY_MB)' \
	VM_DISK_GB='$(VM_DISK_GB)' \
	VM_TAGS='$(or $(VM_TAGS),$(tags))' \
	ACTION=destroy $(AUTOMATION_DIR)/scripts/device-vm.sh

configure: automation-init-files ansible-bootstrap
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/demo_up.yml

plan: tf-plan

up: tf-up configure

down: tf-down

create-rhel9:
	$(AUTOMATION_DIR)/scripts/create-rhel9.sh

aap-install: automation-init-files ansible-bootstrap
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/aap_install.yml

aap-integrate: automation-init-files ansible-bootstrap
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/aap_integration.yml

aap-setup: aap-install aap-integrate

bootc-build: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/bootc-build.sh

approve-enrollment: automation-init-files ansible-bootstrap
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	$(AUTOMATION_DIR)/scripts/approve-enrollment.sh

fleet-apply: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/fleet-apply.sh

device-demo: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/bootc-build.sh
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	ACTION=apply $(AUTOMATION_DIR)/scripts/device-vm.sh
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	WAIT_FOR_PENDING=true WAIT_TIMEOUT_SECONDS=1800 $(AUTOMATION_DIR)/scripts/approve-enrollment.sh
	$(AUTOMATION_DIR)/scripts/fleet-apply.sh

app-build: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/app-build.sh

app-deploy: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/app-deploy.sh

app-demo: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/app-build.sh
	$(AUTOMATION_DIR)/scripts/app-deploy.sh
