# Navigate to the root of your project
cd STIGFixes/

# Run all RHEL 8 STIGs
ansible-playbook -i inventories/test.yml stig_remediation.yml --vault-id rhel8@prompt

# Or, run a specific STIG
ansible-playbook -i inventories/test.yml stig_remediation.yml --tags "stig_274877" --vault-id rhel8@prompt