#!/usr/bin/env bash
# Script for uncommenting SNO clusters per argocd application and committing them into the source repo
#
# Usage: deploy-ztp.sh <clusters-start> <clusters-end> <sleep-period>
#

set -o pipefail
set -o nounset

# Start ztp-clusters-01 until ztp-clusters-25 every 2 hours
cluster_start=${1:-'1'}
cluster_end=${2:-'25'}
sleep_period=${1:-'7200'}

start_dt=$(date -u +%Y%m%d-%H%M%S)
log_file=deploy-${start_dt}.log

rhacm_ztp_directory={{ rhacm_install_directory }}/rhacm-ztp

echo "$(date -u +%Y%m%d-%H%M%S) - ZTP Deployment Test" | tee -a ${log_file}
echo "$(date -u +%Y%m%d-%H%M%S) - Clusters Start: ${cluster_start}" | tee -a ${log_file}
echo "$(date -u +%Y%m%d-%H%M%S) - Clusters End: ${cluster_end}" | tee -a ${log_file}
echo "$(date -u +%Y%m%d-%H%M%S) - Sleep Period: ${sleep_period}" | tee -a ${log_file}

for idx in `seq -f "%02g" ${cluster_start} ${cluster_end}`; do
  echo "$(date -u +%Y%m%d-%H%M%S) - Sed in ${rhacm_ztp_directory}/cnf-features-deploy/ztp/gitops-subscriptions/argocd/cluster/ztp-clusters-${idx}/kustomization.yaml" | tee -a ${log_file}
  sed -i 's/^#//g' ${rhacm_ztp_directory}/cnf-features-deploy/ztp/gitops-subscriptions/argocd/cluster/ztp-clusters-${idx}/kustomization.yaml 2>&1 | tee -a ${log_file}
  echo "$(date -u +%Y%m%d-%H%M%S) - git add ${rhacm_ztp_directory}/cnf-features-deploy/ztp/gitops-subscriptions/argocd/cluster/ztp-clusters-${idx}/kustomization.yaml" | tee -a ${log_file}
  git -C ${rhacm_ztp_directory}/cnf-features-deploy/ add ${rhacm_ztp_directory}/cnf-features-deploy/ztp/gitops-subscriptions/argocd/cluster/ztp-clusters-${idx}/kustomization.yaml 2>&1 | tee -a ${log_file}
  echo "$(date -u +%Y%m%d-%H%M%S) - git commit -m \"Deploying ztp-clusters-${idx}\"" | tee -a ${log_file}
  git -C ${rhacm_ztp_directory}/cnf-features-deploy/ commit -m "Deploying ztp-clusters-${idx}" 2>&1 | tee -a ${log_file}
  echo "$(date -u +%Y%m%d-%H%M%S) - git push origin-gogs" | tee -a ${log_file}
  git -C ${rhacm_ztp_directory}/cnf-features-deploy/ push origin-gogs 2>&1 | tee -a ${log_file}
  echo "$(date -u +%Y%m%d-%H%M%S) - Sleeping ... ${sleep_period}" | tee -a ${log_file}
  sleep ${sleep_period}
done
echo "$(date -u +%Y%m%d-%H%M%S) - ZTP Deployment completed" | tee -a ${log_file}
