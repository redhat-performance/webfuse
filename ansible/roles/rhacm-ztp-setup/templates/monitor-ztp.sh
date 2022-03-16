#!/usr/bin/env bash
# Script to count SNOs initilized, booted, provisioned, managed and compliant
#
# Usage: monitor-ztp.sh [sleep-period]
#

set -o pipefail
set -o nounset

sleep_period=${1:-'60'}

start_dt=$(date -u +%Y%m%d-%H%M%S)
csv_file=ztp-${start_dt}.csv
log_file=monitor-${start_dt}.log

export KUBECONFIG={{ hub_cluster_kubeconfig }}

echo "date,initialized,booted,discovered,provisioning,install_failed,install_completed,managed,compliant" > ${csv_file} | tee -a ${log_file}

while true; do
  cur_dt=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  aci_completed=$(oc get agentclusterinstall -A --no-headers -o custom-columns=COMPLETED:'.status.conditions[?(@.type=="Completed")].reason',name:'.metadata.name' 2>> ${log_file})
  cd_installed=$(oc get clusterdeployment -A --no-headers -o custom-columns=INSTALLED:'.spec.installed',NAME:'.spec.clusterName' 2>> ${log_file})
  cgu_ready=$(oc get clustergroupupgrades -n ztp-install --no-headers -o custom-columns=READY:'.status.conditions[?(@.type=="Ready")].reason' 2>> ${log_file})

  initialized=$(echo "${cd_installed}" | grep -c sno | tr -d " ")
  booted=$(oc get bmh -A --no-headers -o custom-columns=NAME:.metadata.name,PROVISIONED:.status.provisioning.state | grep -c provisioned)
  discovered=$(oc get agent -A --no-headers | wc -l | tr -d " ")

  provisioning=$(echo "${aci_completed}" | grep -c InstallationInProgress | tr -d " ")
  install_failed=$(echo "${aci_completed}" | grep -c InstallationFailed | tr -d " ")
  install_completed=$(echo "${cd_installed}" | grep -i -c true | tr -d " ")

  managed=$(oc get managedcluster -A --no-headers -o custom-columns=JOINED:'.status.conditions[?(@.type=="ManagedClusterJoined")].status',AVAILABLE:'.status.conditions[?(@.type=="ManagedClusterConditionAvailable")].status' | grep -v none | grep -i true | grep -v Unknown | wc -l | tr -d " ")
  compliant=$(echo "$cgu_ready" | grep -c UpgradeCompleted | tr -d " ")

  echo "${cur_dt} #########################" | tee -a ${log_file}
  echo "${cur_dt} initialized: ${initialized}" | tee -a ${log_file}
  echo "${cur_dt} booted: ${booted}" | tee -a ${log_file}
  echo "${cur_dt} discovered: ${discovered}" | tee -a ${log_file}
  echo "${cur_dt} provisioning: ${provisioning}" | tee -a ${log_file}
  echo "${cur_dt} install_failed: ${install_failed}" | tee -a ${log_file}
  echo "${cur_dt} install_completed: ${install_completed}" | tee -a ${log_file}
  echo "${cur_dt} managed: ${managed}" | tee -a ${log_file}
  echo "${cur_dt} compliant: ${compliant}" | tee -a ${log_file}

  echo "${cur_dt},${initialized},${booted},${discovered},${provisioning},${install_failed},${install_completed},${managed},${compliant}" >> ${csv_file} | tee -a ${log_file}

  sleep ${sleep_period}
done
