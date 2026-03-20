# Proxmox / RHEL VM — credentials: export PROXMOX_VE_* or use prereqs/terraform/.env
TF_DIR := prereqs/terraform
TF := $(TF_DIR)/tf.sh

.PHONY: tf-init tf-plan tf-up tf-down

tf-init:
	cd $(TF_DIR) && terraform init -input=false

tf-plan:
	$(TF) plan -input=false

tf-up:
	cd $(TF_DIR) && terraform init -input=false && ./tf.sh apply -auto-approve -input=false

tf-down:
	$(TF) destroy -auto-approve -input=false
