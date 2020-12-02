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
4.  Procure Licenses and update details in `ansible/group_vars/all.yml` 
5.  Assign Worker and Interface names under `BigIP playbook vars` section
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

## Nightly Operators

Detailed explaination about nightly operator and installation can be found [here](https://docs.engineering.redhat.com/display/MULTIARCH/How+To+Test+Red+Hat+ART+Operators) and [here](https://gitlab.cee.redhat.com/cf/docs/pipeline/-/blob/master/doc/Operators/Test.md#test)

Vars required to be set in group_vars/all.yml for a nightly build are,

```yml
# Set to true to install nightly Operators and it is effective only for dev-preview builds, 
# if set make sure to provide brew registry password and Index Image Build IDs
nightly_operator: true

# Required only for nightly operator installtion
brew_reg_password: ""

# Required only for nightly operator installtion
iib_id:
  sriov: 25944    #openshift-sriov-network-operator
  osv: 26761     #openshift-virtualization 
  clo: 26761     #cluster-logging-operator
  amq: 26761     #amq-operator
  pao: 26761     #performance-addon-operator
  eso: 26761     #elastic-search-operator
```

To get your access to Brew registry, you must email operator-pipeline-wg@redhat.com w/ your email address and GPG key. You will receive an encrypted file which contains your password, use that as `brew_reg_password`

IIB - Index Image Builder is an api based platform used to add and remove operator bundles from index images, details [here](https://gitlab.cee.redhat.com/ocp-edge-qe/ocp-edge/-/blob/master/docs/index-images-4.6.md#index-image-build-process)

To get the right IIB IDs, find the operator version from this [link](http://external-ci-coldstorage.datahub.redhat.com/cvp/cvp-redhat-operator-bundle-image-validation-test/)(takes longer to load) and navigate to `index_image.txt` file to get the ID or navigate to cvp-test-report.html file and look for Index Image Location section.

Example file for SRIOV Operator 4.7 - [here](http://external-ci-coldstorage.datahub.redhat.com/cvp/cvp-redhat-operator-bundle-image-validation-test/sriov-network-operator-metadata-container-v4.7.0.202012021303.p0-1/ade5976a-0d9b-47cf-9d50-f42c2b4f5758/index_images.yml)

All latest opertators possibly be available in same IIB build, in that case provide that ID to all operators in `iib_id`.  
To check included operator and version try [this](https://gitlab.cee.redhat.com/ocp-edge-qe/ocp-edge/-/blob/master/docs/index-images-4.6.md#identifying-which-operator-bundle-pointers-exist-in-an-index-image)

```sh
$ podman login brew.registry.redhat.io --tls-verify=false
Username: |shared-qe-temp.zmns.153b77
Password: <YOUR BREW REG PASS>
Login Succeeded!

$ podman run --name indeximage --rm -p 50051:50051 brew.registry.redhat.io/rh-osbs/iib-pub-pending:26761
```
And GRPCURL it to find the available version, 
```sh
$ grpcurl -plaintext -d '{"name":"sriov-network-operator"}' localhost:50051 api.Registry/GetPackage
{
  "name": "sriov-network-operator",
  "channels": [
    {
      "name": "4.6",
      "csvName": "sriov-network-operator.4.6.0-202010311441.p0"
    }
  ],
  "defaultChannelName": "4.6"
}
```
