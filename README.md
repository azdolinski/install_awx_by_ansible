# AWX Installation Automation with Ansible

This Ansible project automates the installation of AWX on a CentOS system using K3s, following the process described in the [awx-on-k3s](https://github.com/kurokobo/awx-on-k3s) project.


# insert docs mp4



## Project Structure

```text
install_awx_by_ansible/
├── ansible.cfg             # Ansible configuration file
├── inventories/
│   ├── hosts.example.yml   # Example inventory file
│   └── hosts.yml           # Inventory file
├── group_vars/
│   └── awx_servers.yml     # Group variables for AWX servers
├── roles/
│   ├── update_system/      # Role to update system packages
│   ├── prepare_centos/     # Role to prepare CentOS host
│   ├── install_k3s/        # Role to install K3s
│   ├── install_k9s/        # Role to install K9s CLI tool
│   ├── install_awx_operator/ # Role to install AWX Operator
│   ├── prepare_awx_files/  # Role to prepare AWX files
│   └── deploy_awx/         # Role to deploy AWX
├── site.yml                # Main playbook for AWX installation
└── run.sh                  # Installation script
```

## Prerequisites

- Target host running CentOS Stream 9
- SSH access to the target host
- Ansible installed on the control node

## Configuration

Before running the playbook, update the following files:

1. **inventories/hosts.yml**: Update with your target host information
2. **group_vars/awx_servers.yml**: Update configuration variables, especially:
   - `awx_hostname`: The hostname for your AWX instance
   - `postgres_password`: PostgreSQL database password
   - `admin_password`: AWX admin user password

## Usage

1. Update the variables in the hosts.yml file with your specific environment details.

    ```bash
    nano group_vars/awx_servers.yml
    ```

2. Run the installation script:

    ```bash
    bash run.sh
    ```

The script will:
  • Set up a local Python virtual environment
  • Install local required dependencies
  • Prompt for configuration values
  • Run the Ansible playbook and install k3s/AWX on remote host

Alternatively, you can run the playbook directly:

```bash
ansible-playbook -i inventories/hosts.yml site.yml
```

You can also run specific parts of the installation using tags:

### Running Specific Parts of the Installation

```bash
# Prepare CentOS only
ansible-playbook -i inventories/hosts.yml site.yml --tags=prepare,centos

# Install K3s only
ansible-playbook -i inventories/hosts.yml site.yml --tags=install,k3s

# Install AWX Operator only
ansible-playbook -i inventories/hosts.yml site.yml --tags=install,awx,operator

# Prepare AWX files only
ansible-playbook -i inventories/hosts.yml site.yml --tags=prepare,awx,files

# Deploy AWX only
ansible-playbook -i inventories/hosts.yml site.yml --tags=deploy,awx
```

## Notes

- The installation process may take 10-15 minutes to complete.
- After installation, you will need to configure your DNS or hosts file to properly resolve the hostname you specified for AWX.
- Default credentials for AWX will be displayed at the end of the playbook run.

## System Requirements

As per the original documentation:

- Computing resources:
  - 2 CPUs minimum
  - 4 GiB RAM minimum
  - Recommended: 4 CPUs and 8 GiB RAM or more
- Storage resources:
  - At least 10 GiB for `/var/lib/rancher`
  - At least 10 GiB for `/data`
