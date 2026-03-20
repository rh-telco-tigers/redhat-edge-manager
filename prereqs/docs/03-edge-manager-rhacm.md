# Step 3 — Red Hat Edge Manager (RHEM) on RHACM

Per Red Hat: [Edge Manager introduction & architecture](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.13/html/edge_manager/edge-mgr-intro#rhem-architecture).

## Reality check (one VM vs product design)

- **RHEM (flightctl)** in this doc runs on the **Red Hat Advanced Cluster Management hub** (OpenShift), not on the same small RHEL VM as AAP.
- Your **Proxmox VM** is a good place for **AAP** and for **bootc image builds** (Podman). It is **not** a substitute for an OCP+RHACM hub.

Minimum demo path for **RHEM UI/API**:

1. Have (or install) an **OpenShift** cluster with **RHACM** installed.
2. Run the **enable** and **verify** steps below from a host with `oc` and a cluster-admin kubeconfig.

## Enable RHEM (cluster admin)

```bash
export KUBECONFIG=/path/to/hub-kubeconfig

oc patch multiclusterhubs.operator.open-cluster-management.io multiclusterhub \
  -n rhacm \
  --type json \
  --patch '[{"op": "add", "path":"/spec/overrides/components/-", "value": {"name":"edge-manager-preview","enabled": true}}]'
```

> If your `MultiClusterHub` lives in another namespace, change `-n rhacm` (some installs use `open-cluster-management`).

## Verify API pod

```bash
oc -n open-cluster-management get pods | grep flightctl-api
# Expect Running, e.g. flightctl-api  2/2  Running
```

## Enable console plugin (optional)

```bash
oc edit console.operator.openshift.io cluster
# Add flightctl-plugin under spec.plugins (see Red Hat doc)
```

## flightctl CLI on a workstation

RHACM doc: enable repo `rhacm-2.13-for-rhel-<version>-<arch>-rpms`, then `dnf install flightctl`. Login against your **RHEM user-facing API URL** (from RHACM/Edge Manager route — use your cluster’s actual hostname).

## Ansible

Use [playbooks/rhem_enable_rhacm.yml](../ansible/playbooks/rhem_enable_rhacm.yml) **from a control node that has `oc` + kubeconfig** (often `localhost` with `ansible_connection: local`).
