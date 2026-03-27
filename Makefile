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
LAB_DEFAULT_SITE ?= homelab
LAB_EARLY_DEVICE_NAME ?= early
LAB_LATE_DEVICE_NAME ?= late
empty :=
space := $(empty) $(empty)
comma := ,
DEVICE_RESERVED_CLI_VARS := name site tags DEVICE_NAME DEVICE_SITE DEVICE_LABEL_KVS BOOTC_QCOW2_PATH UPLOADED_QCOW2_FILE_NAME VM_ID vm_id VM_NAME vm_name VM_DESCRIPTION VM_CORES VM_MEMORY_MB VM_DISK_GB VM_TAGS ACTION WAIT_FOR_PENDING WAIT_TIMEOUT_SECONDS WAIT_POLL_INTERVAL_SECONDS
COMMAND_LINE_VARS := $(sort $(foreach v,$(.VARIABLES),$(if $(filter command line,$(origin $(v))),$(v))))
DEVICE_LABEL_KVS_VALUE := $(strip $(foreach v,$(COMMAND_LINE_VARS),$(if $(filter-out $(DEVICE_RESERVED_CLI_VARS),$(v)),$(v)=$($(v)))))

.PHONY: help init-files automation-init-files ansible-bootstrap
.PHONY: plan-lab start-lab stop-lab configure-lab lab-demo-flow
.PHONY: start-satellite stop-satellite start-keycloak stop-keycloak
.PHONY: start-demo-vms stop-demo-vms create-vm
.PHONY: install-aap connect-aap setup-aap build-image-early build-image-late approve-device apply-fleet
.PHONY: build-app deploy-app demo-app
.PHONY: add-device remove-device device-vms-down-all demo-early demo-late
.PHONY: up down plan configure
.PHONY: rhel-vms-init rhel-vms-plan rhel-vms-up rhel-vms-down
.PHONY: create-rhel9 aap-install aap-integrate aap-setup bootc-build bootc-build-earlybinding bootc-build-latebinding approve-enrollment fleet-apply
.PHONY: app-build app-deploy app-demo
.PHONY: device-vm-init device-vm-plan device-vm-up device-vm-down device-demo device-demo-latebinding
.PHONY: tf-init tf-plan tf-up tf-down

help:
	@printf "%s\n" \
	"Supported targets:" \
	"  make help             Show this help" \
	"  make init-files       Seed local gitignored config files" \
	"  make start-lab        Full lab: infra, early+late devices, fleet, and application" \
	"  make stop-lab         Tear down the full lab, including device VMs" \
	"  make plan-lab         Preview Terraform changes for the full lab" \
	"  make configure-lab    Run only the Ansible configuration phase" \
	"  make start-demo-vms   Create only the base RHEL 9 VMs for the manual path" \
	"  make stop-demo-vms    Destroy only those base RHEL 9 VMs" \
	"  make create-vm        Create one standalone RHEL 9 VM" \
	"  make start-satellite  Create the standalone Satellite VM and install Satellite on it" \
	"  make stop-satellite   Destroy the standalone Satellite VM" \
	"  make start-keycloak   Create the standalone Keycloak VM and install Keycloak on it" \
	"  make stop-keycloak    Destroy the standalone Keycloak VM" \
	"  make install-aap      Install Ansible Automation Platform on the AAP host" \
	"  make connect-aap      Configure Edge Manager to use AAP authentication" \
	"  make setup-aap        Run both AAP install and AAP integration" \
	"  make build-image-early Build bootc/earlybinding, push it to Satellite, and fetch the bootable qcow2" \
	"  make build-image-late Build bootc/latebinding and fetch the qcow2 plus cloud-init user-data" \
	"  make add-device       Create one named demo device VM; pass name=<device> site=<site> env=lab" \
	"  make remove-device    Destroy one named demo device VM; pass name=<device>" \
	"  make approve-device   Approve pending requests; pass name=<device> to reuse stored labels" \
	"  make apply-fleet      Create or update the demo Edge Manager fleet" \
	"  make demo-early       Run the early-binding device flow through fleet assignment" \
	"  make demo-late        Run the late-binding device flow through fleet assignment" \
	"  make build-app        Build the applications/hello-web/ images and push them to Satellite" \
	"  make deploy-app       Apply applications/hello-web/fleet-with-app.yaml through Edge Manager" \
	"  make demo-app         Build and deploy the demo application after Labs 3 to 5 are complete"

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

add-device: device-vm-init
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

remove-device: device-vm-init
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

device-vms-down-all: device-vm-init
	$(AUTOMATION_DIR)/scripts/device-vm-down-all.sh

configure-lab: automation-init-files ansible-bootstrap
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/demo_up.yml

plan-lab: tf-plan

lab-demo-flow: automation-init-files ansible-bootstrap
	$(MAKE) demo-early name='$(LAB_EARLY_DEVICE_NAME)' site='$(LAB_DEFAULT_SITE)' binding=early
	$(MAKE) demo-late name='$(LAB_LATE_DEVICE_NAME)' site='$(LAB_DEFAULT_SITE)' binding=late
	$(MAKE) demo-app

start-lab: automation-init-files ansible-bootstrap
	$(MAKE) tf-up
	$(MAKE) configure-lab
	$(MAKE) lab-demo-flow

stop-lab: device-vms-down-all tf-down

create-vm:
	$(AUTOMATION_DIR)/scripts/create-rhel9.sh

start-satellite: automation-init-files ansible-bootstrap
	ROLE=satellite ACTION=start bash $(AUTOMATION_DIR)/scripts/service-vm.sh

stop-satellite: automation-init-files
	ROLE=satellite ACTION=stop bash $(AUTOMATION_DIR)/scripts/service-vm.sh

start-keycloak: automation-init-files ansible-bootstrap
	ROLE=keycloak ACTION=start bash $(AUTOMATION_DIR)/scripts/service-vm.sh

stop-keycloak: automation-init-files
	ROLE=keycloak ACTION=stop bash $(AUTOMATION_DIR)/scripts/service-vm.sh

install-aap: automation-init-files ansible-bootstrap
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/aap_install.yml

connect-aap: automation-init-files ansible-bootstrap
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/aap_integration.yml

setup-aap: install-aap connect-aap

build-image-early: automation-init-files ansible-bootstrap
	BOOTC_BINDING_MODE=earlybinding $(AUTOMATION_DIR)/scripts/bootc-build.sh

build-image-late: automation-init-files ansible-bootstrap
	BOOTC_BINDING_MODE=latebinding $(AUTOMATION_DIR)/scripts/bootc-build.sh

approve-device: automation-init-files ansible-bootstrap
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	$(AUTOMATION_DIR)/scripts/approve-enrollment.sh

apply-fleet: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/fleet-apply.sh

demo-early: automation-init-files ansible-bootstrap
	BOOTC_BINDING_MODE=earlybinding $(AUTOMATION_DIR)/scripts/bootc-build.sh
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name),$(LAB_EARLY_DEVICE_NAME))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site),$(LAB_DEFAULT_SITE))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	ACTION=apply $(AUTOMATION_DIR)/scripts/device-vm.sh
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name),$(LAB_EARLY_DEVICE_NAME))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site),$(LAB_DEFAULT_SITE))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	WAIT_FOR_PENDING=true WAIT_TIMEOUT_SECONDS=1800 $(AUTOMATION_DIR)/scripts/approve-enrollment.sh
	$(AUTOMATION_DIR)/scripts/fleet-apply.sh

demo-late: automation-init-files ansible-bootstrap
	BOOTC_BINDING_MODE=latebinding $(AUTOMATION_DIR)/scripts/bootc-build.sh
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name),$(LAB_LATE_DEVICE_NAME))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site),$(LAB_DEFAULT_SITE))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	ACTION=apply $(AUTOMATION_DIR)/scripts/device-vm.sh
	DEVICE_NAME='$(or $(DEVICE_NAME),$(name),$(LAB_LATE_DEVICE_NAME))' \
	DEVICE_SITE='$(or $(DEVICE_SITE),$(site),$(LAB_DEFAULT_SITE))' \
	DEVICE_LABEL_KVS='$(DEVICE_LABEL_KVS_VALUE)' \
	WAIT_FOR_PENDING=true WAIT_TIMEOUT_SECONDS=1800 $(AUTOMATION_DIR)/scripts/approve-enrollment.sh
	$(AUTOMATION_DIR)/scripts/fleet-apply.sh

build-app: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/app-build.sh

deploy-app: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/app-deploy.sh

demo-app: automation-init-files ansible-bootstrap
	$(AUTOMATION_DIR)/scripts/app-build.sh
	$(AUTOMATION_DIR)/scripts/app-deploy.sh

up: start-lab

down: stop-lab

plan: plan-lab

configure: configure-lab

start-demo-vms: rhel-vms-up

stop-demo-vms: rhel-vms-down

create-rhel9: create-vm

aap-install: install-aap

aap-integrate: connect-aap

aap-setup: setup-aap

bootc-build: build-image-early

bootc-build-earlybinding: build-image-early

bootc-build-latebinding: build-image-late

device-vm-up: add-device

device-vm-down: remove-device

approve-enrollment: approve-device

fleet-apply: apply-fleet

device-demo: demo-early

device-demo-latebinding: demo-late

app-build: build-app

app-deploy: deploy-app

app-demo: demo-app
