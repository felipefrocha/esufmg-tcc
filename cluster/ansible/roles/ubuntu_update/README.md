Role Name
=========

Ubuntu configuration for python3 and commom packages

Requirements
------------

There is any requirement for this repository

Role Variables
--------------

### Default
```yaml
ssh_pubkey_path: String - Path to your public key

hostname:
  enabled: Boolean
  name: String

ubuntu:
  packages: List - Ubuntu Default packages

python:
  enabled: Boolean
  packages: List - Ubuntu Default packages related with python
  requirements: List - Pip Default packages
```
Dependencies
------------

None

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - role: ubuntu_update
            vars:
              hostname:
                enabled: False
              python:
                enabled: False
              ubuntu:
                packages:
                  - net-utils

License
-------

BSD

Author Information
------------------

@_felipefrocha
