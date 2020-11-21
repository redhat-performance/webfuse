# webfuse

## Requirements

`export KUBECONFIG=<path-to-kubeconfig-on-ansible-controller>`

`pip3 install openshift`

`ansible-galaxy collection install amazon.aws`
`ansible-galaxy collection install community.aws`

Ansible >= 2.9

## Usage

Populate the inventory file in [inventory](ansible/inventory/hosts)

```
[orchestration]
localhost ansible_connection=local
```

Populate the required [variables](ansible/group_vars/all.yml)

Then,

`ansible-playbook -i inventory/hosts webscale.yml`

