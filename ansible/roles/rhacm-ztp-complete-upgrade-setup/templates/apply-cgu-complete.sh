#!/usr/bin/env bash
{% for cgu in range(((ztp_done_clusters.stdout_lines | length) / snos_per_cgu) | round(0, 'ceil') | int) %}
date -u
oc apply -f {{ rhacm_install_directory }}/rhacm-ztp/upgrade/cgu-complete-upgrade-{{ du_upgrade_version | replace('.', '-') }}-{{ '%04d' | format(cgu) }}.yml
{% if not loop.last %}
# sleep {{ (complete_upgrade_timeout + complete_upgrade_apply_offset) * 60 }}
{% endif %}
{% endfor %}
