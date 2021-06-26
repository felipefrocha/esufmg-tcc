Kubeadm
=========

This role intents to create a initial configuration for a Ubuntu server with `kubeadm` 

Requirements
------------

To test this role we are using [Molecule](https://molecule.readthedocs.io/) &reg. So you should configure your machine to be able to useit.
Another requirements if there is any will be describe in two files:
* requirements.yml
* requirements.txt
  
The first one should be installed with `pip3` this will install any `python3` dependencies and will be also described in `Makefile`.

The secont one should be installed with `ansible-galaxy` and probabily will be if you use `make`.

### Docs in progress



Role Variables
--------------

All variable descrived in default are from the k8s documentation for cluster installation
The single on you can choose is `package.enabled` which can be `true` for install from ubuntu pkg manager
or `false` for installation from source/binaries

Dependencies
------------

[Ubuntu Update](https://github.com/felipefrocha/ansible-role-ubuntu-update.git)

Example Playbook
----------------

```yaml
    - hosts: k8s_nodes
      roles:
        - role: kubeadm_install
          vars:
            package:
              enabled: True
```
License
-------

BSD

Author Information
------------------

@_felipefrocha
