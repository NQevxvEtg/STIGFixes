# STIGFixes 🛡️

This repository contains Ansible playbooks to apply Security Technical Implementation Guide (STIG) remediations

-----

## ▶️ Usage

First, ensure you are in the root directory of the project.

```bash
cd STIGFixes/
```

The following commands demonstrate how to execute the Ansible playbook.

### Apply All STIGs

To run the complete set of RHEL 8 STIG remediations against the hosts defined in `inventories/test.yml`, use the following command. You'll be prompted for the vault password.

```bash
ansible-playbook -i inventories/test.yml stig_remediation.yml --vault-id rhel8@prompt
```

-----

### Apply a Specific STIG

If you only need to apply a single STIG, you can target it using the `--tags` flag. In this example, we're targeting `stig_274877`.

```bash
ansible-playbook -i inventories/test.yml stig_remediation.yml --tags "stig_274877" --vault-id rhel8@prompt
```