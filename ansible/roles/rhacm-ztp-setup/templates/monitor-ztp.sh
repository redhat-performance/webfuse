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

echo "date,sno_init,notstarted,booted,discovered,installing,install_failed,install_completed,managed,policy_init,policy_applying,policy_timedout,policy_compliant" > ${csv_file} | tee -a ${log_file}

while true; do
  cur_dt=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  aci_completed=$(oc get agentclusterinstall -A --no-headers -o custom-columns=NAME:'.metadata.name',COMPLETED:'.status.conditions[?(@.type=="Completed")].reason' 2>> ${log_file})
  cgu_ready=$(oc get clustergroupupgrades -n ztp-install --no-headers -o custom-columns=NAME:'.metadata.name',READY:'.status.conditions[?(@.type=="Ready")].reason' 2>> ${log_file})

  sno_init=$(echo "${aci_completed}" | grep -c sno | tr -d " ")
  booted=$(oc get bmh -A --no-headers -o custom-columns=NAME:'.metadata.name',PROVISIONED:'.status.provisioning.state' | grep -c provisioned)
  discovered=$(oc get agent -A --no-headers | wc -l | tr -d " ")

  notstarted=$(echo "${aci_completed}" | grep -c InstallationNotStarted | tr -d " ")
  installing=$(echo "${aci_completed}" | grep -c InstallationInProgress | tr -d " ")
  install_failed=$(echo "${aci_completed}" | grep -c InstallationFailed | tr -d " ")
  install_completed=$(echo "${aci_completed}" | grep -c InstallationCompleted | tr -d " ")

  managed=$(oc get managedcluster -A --no-headers -o custom-columns=JOINED:'.status.conditions[?(@.type=="ManagedClusterJoined")].status',AVAILABLE:'.status.conditions[?(@.type=="ManagedClusterConditionAvailable")].status' | grep -v none | grep -i true | grep -v Unknown | wc -l | tr -d " ")
  policy_init=$(echo "$cgu_ready" | wc -l)
  policy_applying=$(echo "$cgu_ready" | grep -c UpgradeNotCompleted | tr -d " ")
  policy_timedout=$(echo "$cgu_ready" | grep -c UpgradeTimedOut | tr -d " ")
  policy_compliant=$(echo "$cgu_ready" | grep -c UpgradeCompleted | tr -d " ")

  echo "${cur_dt} #########################" | tee -a ${log_file}
  echo "${cur_dt} sno init: ${sno_init}" | tee -a ${log_file}
  echo "${cur_dt} notstarted: ${notstarted}" | tee -a ${log_file}
  echo "${cur_dt} booted: ${booted}" | tee -a ${log_file}
  echo "${cur_dt} discovered: ${discovered}" | tee -a ${log_file}
  echo "${cur_dt} installing: ${installing}" | tee -a ${log_file}
  echo "${cur_dt} install_failed: ${install_failed}" | tee -a ${log_file}
  echo "${cur_dt} install_completed: ${install_completed}" | tee -a ${log_file}
  echo "${cur_dt} managed: ${managed}" | tee -a ${log_file}
  echo "${cur_dt} policy_init: ${policy_init}" | tee -a ${log_file}
  echo "${cur_dt} policy_applying: ${policy_applying}" | tee -a ${log_file}
  echo "${cur_dt} policy_timedout: ${policy_timedout}" | tee -a ${log_file}
  echo "${cur_dt} policy_compliant: ${policy_compliant}" | tee -a ${log_file}

  echo "${cur_dt},${sno_init},${notstarted},${booted},${discovered},${installing},${install_failed},${install_completed},${managed},${policy_init},${policy_applying},${policy_timedout},${policy_compliant}" >> ${csv_file} | tee -a ${log_file}

  sleep ${sleep_period}
done
