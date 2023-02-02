#!/usr/bin/env bash
{% for cgu in range(((ztp_done_clusters.stdout_lines | length) / snos_per_cgu) | round(0, 'ceil') | int) %}
date -u
oc --namespace=ztp-platform-upgrade patch clustergroupupgrade.ran.openshift.io/complete-upgrade-{{ du_upgrade_version | replace('.', '-') }}-{{ '%04d' | format(cgu) }} --patch '{"spec":{"enable":true}}' --type=merge
{% if not loop.last %}
sleep {{ (complete_upgrade_patch_sleep + complete_upgrade_apply_patch_offset) * 60 }}
{% endif %}
{% endfor %}
