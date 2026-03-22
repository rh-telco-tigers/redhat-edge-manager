# Edge Manager through RHACM reference

This is an alternate deployment model. It is not the same path as Lab 1, which installs Edge Manager directly on RHEL.

Source of truth:
[Red Hat Advanced Cluster Management Edge Manager documentation](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/)

## What this path requires

- an OpenShift hub cluster
- RHACM installed on that hub
- a control node with `oc`
- cluster-admin access

## Minimal enablement flow

```bash
export KUBECONFIG=/path/to/hub-kubeconfig

oc patch multiclusterhubs.operator.open-cluster-management.io multiclusterhub \
  -n rhacm \
  --type json \
  --patch '[{"op":"add","path":"/spec/overrides/components/-","value":{"name":"edge-manager-preview","enabled":true}}]'
```

If your `MultiClusterHub` resource lives in a different namespace, adjust `-n rhacm`.

## Verification

```bash
oc -n open-cluster-management get pods | grep flightctl-api
```

You should see the Edge Manager API pod running.

## Repo automation hook

If you want to use this repo to apply the enablement patch from a prepared control node, use:

[`automation/ansible/playbooks/rhem_enable_rhacm.yml`](../../automation/ansible/playbooks/rhem_enable_rhacm.yml)
