#!/usr/bin/env bash
{% for cgu in range(((ztp_done_clusters.stdout_lines | length) / snos_per_cgu) | round(0, 'ceil') | int) %}
oc --namespace=ztp-platform-upgrade patch clustergroupupgrade.ran.openshift.io/cgu-platform-upgrade-{{ du_upgrade_version | replace('.', '-')  }}-{{ '%04d' | format(cgu) }} --patch '{"spec":{"enable":true}}' --type=merge
{% endfor %}
