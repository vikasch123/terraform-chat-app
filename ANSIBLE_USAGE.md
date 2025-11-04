# Using Terraform-Generated Inventory with Ansible

This guide explains how to use the dynamically generated `inventory.yaml` file from the Terraform project in a separate Ansible project.

## Prerequisites

1. **Terraform infrastructure is provisioned:**
   ```bash
   cd /home/vk/terraform-chat-vpc
   terraform apply
   ```
   
   **Note:** The `inventory.yaml` file is **not** in the repository—it's generated automatically by Terraform when you run `terraform apply`. The file is created by the `local_file.ansible_inventory` resource in `main.tf`, which uses `templatefile()` to process `inventory.tmpl` and fill in the actual IP addresses and key paths.

2. **Files generated after `terraform apply` in Terraform project:**
   - `inventory.yaml` - Ansible inventory file (auto-generated)
   - `web.pem` - SSH key for web server (auto-generated)
   - `app.pem` - SSH key for app server (auto-generated)
   - `db.pem` - SSH key for database server (auto-generated)

## Method 1: Direct Path Reference (Easiest)

**Important:** The `inventory.yaml` file doesn't exist in the codebase yet. It will be automatically generated when you run `terraform apply`. After Terraform creates your infrastructure, the file will be created at `/home/vk/terraform-chat-vpc/inventory.yaml`.

Use the absolute path to the inventory file when running Ansible commands:

```bash
# First, ensure Terraform has created the infrastructure and inventory file
cd /home/vk/terraform-chat-vpc
terraform apply
# This will generate inventory.yaml along with the *.pem key files

# Then navigate to your Ansible project
cd /path/to/your/ansible-project

# Run Ansible playbook with absolute path to inventory
ansible-playbook -i /home/vk/terraform-chat-vpc/inventory.yaml site.yml

# Test connectivity
ansible all -i /home/vk/terraform-chat-vpc/inventory.yaml -m ping

# Run ad-hoc commands
ansible web -i /home/vk/terraform-chat-vpc/inventory.yaml -m shell -a "hostname"
```

**Note:** With the updated code, key paths in `inventory.yaml` are now absolute, so this works from any directory.

## Method 2: Configure ansible.cfg (Recommended for Development)

Create or update `ansible.cfg` in your Ansible project:

```ini
[defaults]
inventory = /home/vk/terraform-chat-vpc/inventory.yaml
host_key_checking = False
remote_user = ec2-user
private_key_file = /home/vk/terraform-chat-vpc/web.pem
```

Now you can run Ansible without the `-i` flag:
```bash
cd /path/to/your/ansible-project
ansible-playbook site.yml
ansible all -m ping
```

## Method 3: Symbolic Link (Good for Shared Projects)

Create a symlink in your Ansible project:

```bash
# In your Ansible project directory
cd /path/to/your/ansible-project
ln -s /home/vk/terraform-chat-vpc/inventory.yaml inventory.yaml

# Also symlink the key files (optional, if using relative paths)
ln -s /home/vk/terraform-chat-vpc/web.pem web.pem
ln -s /home/vk/terraform-chat-vpc/app.pem app.pem
ln -s /home/vk/terraform-chat-vpc/db.pem db.pem

# Now use relative path
ansible-playbook -i inventory.yaml site.yml
```

## Method 4: Copy to Ansible Project (Isolated)

Copy the inventory and keys to your Ansible project:

```bash
# Copy inventory file
cp /home/vk/terraform-chat-vpc/inventory.yaml /path/to/your/ansible-project/

# Copy key files
cp /home/vk/terraform-chat-vpc/*.pem /path/to/your/ansible-project/

# Update permissions on keys
chmod 600 /path/to/your/ansible-project/*.pem

# Use in Ansible project
cd /path/to/your/ansible-project
ansible-playbook -i inventory.yaml site.yml
```

**Important:** If you copy files, you'll need to update key paths in `inventory.yaml` to match your new location, OR use relative paths in the Terraform template.

## Method 5: Environment Variable

Set an environment variable for the inventory path:

```bash
export ANSIBLE_INVENTORY=/home/vk/terraform-chat-vpc/inventory.yaml

# Now Ansible will use it automatically
ansible all -m ping
ansible-playbook site.yml
```

Or add to your shell profile (`~/.bashrc` or `~/.zshrc`):
```bash
export ANSIBLE_INVENTORY=/home/vk/terraform-chat-vpc/inventory.yaml
```

## Example Ansible Playbook Structure

```
your-ansible-project/
├── ansible.cfg          # Points to Terraform inventory
├── site.yml            # Main playbook
├── playbooks/
│   ├── web.yml         # Web server playbook
│   ├── app.yml         # App server playbook
│   └── db.yml          # Database playbook
└── roles/
    ├── nginx/
    ├── django/
    └── mysql/
```

## Example Playbook (site.yml)

```yaml
---
- name: Configure Web Server
  hosts: web
  become: yes
  roles:
    - nginx

- name: Configure App Server
  hosts: app
  become: yes
  roles:
    - django

- name: Configure Database Server
  hosts: db
  become: yes
  roles:
    - mysql
```

## Testing the Inventory

Verify the inventory works correctly:

```bash
# List all hosts
ansible all -i /home/vk/terraform-chat-vpc/inventory.yaml --list-hosts

# List hosts by group
ansible web -i /home/vk/terraform-chat-vpc/inventory.yaml --list-hosts
ansible app -i /home/vk/terraform-chat-vpc/inventory.yaml --list-hosts
ansible db -i /home/vk/terraform-chat-vpc/inventory.yaml --list-hosts

# Test connectivity (pings)
ansible all -i /home/vk/terraform-chat-vpc/inventory.yaml -m ping

# Get facts from hosts
ansible all -i /home/vk/terraform-chat-vpc/inventory.yaml -m setup
```

## Auto-Update Workflow

When you run `terraform apply`, the inventory is automatically regenerated. To use the updated inventory:

1. **Manual refresh:** Just use the inventory file - it's already updated
2. **Automated refresh:** Create a script that runs Terraform and then runs Ansible:

```bash
#!/bin/bash
# refresh-inventory.sh
cd /home/vk/terraform-chat-vpc
terraform apply -auto-approve
echo "Inventory updated at $(date)"
```

## Troubleshooting

### Issue: "Could not resolve hostname"
- Check that IPs in `inventory.yaml` are correct
- Verify SSH connectivity to the bastion (web server)

### Issue: "Permission denied (publickey)"
- Ensure key files have correct permissions: `chmod 600 *.pem`
- Verify key paths in `inventory.yaml` are correct
- Check that keys match the EC2 key pairs

### Issue: "Host key verification failed"
- Add to your `ansible.cfg`: `host_key_checking = False`
- Or use `-o StrictHostKeyChecking=no` in SSH options

### Issue: "ProxyCommand failed"
- Verify web server (bastion) is accessible
- Check that web server's security group allows SSH (port 22)
- Ensure private instances' security groups allow SSH from web server

## Best Practices

1. **Version Control:** Add `inventory.yaml` and `*.pem` files to `.gitignore` (they contain sensitive info)
2. **Security:** Keep key files secure with 600 permissions
3. **Documentation:** Document which inventory file your playbooks use
4. **Automation:** Consider using CI/CD to regenerate inventory after infrastructure changes
5. **Backup:** Keep backups of key files in a secure location
