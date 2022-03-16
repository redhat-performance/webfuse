#!/usr/bin/env bash
#

export KUBECONFIG={{ hub_cluster_kubeconfig }}

ls /root/hv-sno/manifests/ | xargs -I % sh -c "oc get secret %-admin-kubeconfig -n % -o json | jq -r '.data.kubeconfig' | base64 -d > /root/hv-sno/manifests/%/kubeconfig"
