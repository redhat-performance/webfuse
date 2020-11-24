# webfuse

## Requirements

`export KUBECONFIG=<path-to-kubeconfig-on-ansible-controller>`

`pip3 install openshift netaddr`

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

## BigIP Pre-requisites

Tested for - OCP 4.5.11, 4.6.3

1.  OVN hybrid plugin is required, it has to be manually patched via cluster manifest file during intial deployment, JetSki would take care of this patch. https://github.com/mukrishn/labf5-setup/blob/main/00-network-manifest.yaml
2.  Need at least 1 worker node to host bigip Virtual machines
3.  Install SRIOV and OSV operators in the cluster, so obviously Hardware must support SRIOV and enable BIOs configuration. script for shared lab - https://github.com/mukrishn/sriov-prep
4.  Procure License and update details in `ansible/group_vars/all.yml` 
5.  Assign Worker, License, Interface names and Network variables under `BigIP playbook vars` section
6.  This playbook must be executed from cluster provisioner node, as it creates VLAN sub-interface with private network to connect to VMs.

`ansible-playbook -i inventory/hosts bigip-setup.yml`

### Deactivate the license 

Red Hat procured BigIP Licenses for Dev/Test can be re-used, it has to be revoked properly from existing environment before the expiry date. 

You can use this playbook to do that, 

`hosts` file

```sh
bigip:
  hosts:
    bigip0.apps.test722.myocp4.com:
      ansible_host: "192.168.223.100"
      license_key: "SQWEVQ-MWRFS-UXSWU-NFKCX-NEDFFF"
      bigip_user: "admin"
      bigip_password: "password"

    bigip1.apps.test722.myocp4.com:
      ansible_host: "192.168.223.101"
      license_key: "UDUMT-RVTVT-NAWEX-DPIVS-LNIOPLB"
      bigip_user: "admin"
      bigip_password: "password"
```

`playbook.yml` file

```yml
---
- name: Revoke License
  hosts: [bigip]
  gather_facts: false
  environment:
      F5_SERVER: "{{ ansible_host }}"
      F5_USER: "admin"
      F5_PASSWORD: "password"
      F5_VALIDATE_CERTS: "false"
      F5_SERVER_PORT: 443
  connection: local

  tasks:
    - name: Revoke License
      bigip_device_license:
        accept_eula: true
        license_key: "{{ license_key }}"
        state: revoked
```

Execute - `ansible-playbook -i hosts playbook.yml` to revoke licenses.
