#!/usr/bin/env bash
{% for cgu in range(((operator_update_clusters.stdout_lines | length) / snos_per_cgu) | round(0, 'ceil') | int) %}
oc --namespace=ztp-operator-upgrade patch clustergroupupgrade.ran.openshift.io/cgu-operator-upgrade-{{ disconnected_operator_index_tag | replace('.', '') }}-{{ '%04d' | format(cgu) }} --patch '{"spec":{"enable":true}}' --type=merge
{% endfor %}
