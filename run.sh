#!/bin/bash
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_DIR="${SCRIPT_DIR}/venv"

# Function to collect parameters from user
collect_parameters() {
    echo -e "${BLUE}=== AWX Installation Configuration ===${NC}"
    
    # Define parameters array with keys and default values
    declare -A params=(
        ["AWX_HOSTNAME"]="awx.example.com"
        ["AWX_POSTGRES_PASSWORD"]="Ansible123!"
        ["AWX_ADMIN_PASSWORD"]="Ansible123!"
        ["AWX_HOST_ADDRESS"]="192.168.1.100"
        ["AWX_HOST_USER"]="centos"
        ["AWX_HOST_PASSWORD"]=""
        ["AWX_SUDO_PASSWORD"]=""
    )

    # Load values from .env file if it exists
    ENV_FILE="${SCRIPT_DIR}/.env"
    if [ -f "$ENV_FILE" ]; then
        echo -e "${GREEN}Loading saved configuration from .env file...${NC}"
        # Source the .env file to load variables
        source "$ENV_FILE"
        
        # Update default values with values from .env file
        for key in "${!params[@]}"; do
            env_value=$(eval echo \$$key)
            if [ -n "$env_value" ]; then
                params[$key]="$env_value"
            fi
        done
    fi

    # Descriptions for each parameter
    declare -A descriptions=(
        ["AWX_HOSTNAME"]="AWX hostname (e.g., awx.example.com)"
        ["AWX_POSTGRES_PASSWORD"]="PostgreSQL database password"
        ["AWX_ADMIN_PASSWORD"]="AWX admin user password"
        ["AWX_HOST_ADDRESS"]="Target server IP address"
        ["AWX_HOST_USER"]="SSH username for target server"
        ["AWX_HOST_PASSWORD"]="SSH password for target server (leave empty for key-based auth)"
        ["AWX_SUDO_PASSWORD"]="Sudo password for target server (if required)"
    )

    # Define the order of parameters - this is needed as:
    # In Bash, when using the for key in "${!params[@]}" construct, 
    # keys are returned in the order specified by the internal hash function, 
    # not in the order of declaration.
    param_order=(
        "AWX_HOST_ADDRESS"
        "AWX_HOST_USER"
        "AWX_HOST_PASSWORD"
        "AWX_SUDO_PASSWORD"
        "AWX_HOSTNAME"
        "AWX_ADMIN_PASSWORD"
        "AWX_POSTGRES_PASSWORD"
    )

    # Collect parameters from user in specified order
    for key in "${param_order[@]}"; do
        default_value="${params[$key]}"
        description="${descriptions[$key]}"
        
        # Handle password fields differently (hide input)
        if [[ "$key" == *"PASSWORD"* ]]; then
            echo -e "${MAGENTA}> Enter $description [default: use existing or empty]:${NC}"
            read -s user_input
            echo # Add newline after hidden input
        else
            echo -e "${MAGENTA}> Enter $description [default: $default_value]:${NC}"
            read user_input
        fi
        
        # If user provided input, use it; otherwise use default
        if [ -n "$user_input" ]; then
            export "$key"="$user_input"
            echo -e "${GREEN}$key set${NC}"
        else
            # Only export non-empty defaults
            if [ -n "$default_value" ]; then
                export "$key"="$default_value"
                echo -e "${GREEN}$key - using default: $default_value ${NC}"
            fi
        fi
    done
    
    # Save configuration to .env file
    echo -e "${YELLOW}Saving configuration to .env file...${NC}"
    # Create or truncate the .env file
    > "$ENV_FILE"
    
    # Save each parameter to the .env file
    for key in "${param_order[@]}"; do
        value=$(eval echo \$$key)
        if [ -n "$value" ]; then
            echo "$key=\"$value\"" >> "$ENV_FILE"
        fi
    done
    
    echo -e "${BLUE}Configuration complete!${NC}"
    echo -e "${YELLOW}Review your settings:${NC}"
    echo -e "  AWX Hostname: ${GREEN}$AWX_HOSTNAME${NC}"
    echo -e "  Target Server: ${GREEN}$AWX_HOST_USER@$AWX_HOST_ADDRESS${NC}"
    echo -e "${YELLOW}Passwords are not displayed for security.${NC}"
    
    # Confirm settings
    echo -e "${YELLOW}Do you want to proceed with these settings? (y/n)${NC}"
    read confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborted by user.${NC}"
        exit 1
    fi
}



echo -e "${BLUE}=== AWX Installation Automation ===${NC}"
echo -e "${BLUE}Setting up LOCAL environment...${NC}"

# Step 1: Check if venv exists, if not create it
if [ ! -d "${VENV_DIR}" ]; then
    echo -e "${YELLOW}Virtual environment not found. Creating one...${NC}"
    python3 -m venv "${VENV_DIR}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create virtual environment. Checking if python3-venv is installed...${NC}"
        # Check if we're on a system that might need python3-venv
        if command -v apt-get &> /dev/null; then
            echo -e "${YELLOW}Attempting to install python3-venv...${NC}"
            sudo apt-get update && sudo apt-get install -y python3-venv
            python3 -m venv "${VENV_DIR}"
        elif command -v dnf &> /dev/null; then
            echo -e "${YELLOW}Attempting to install python3-venv...${NC}"
            sudo dnf install -y python3-venv
            python3 -m venv "${VENV_DIR}"
        elif command -v yum &> /dev/null; then
            echo -e "${YELLOW}Attempting to install python3-venv...${NC}"
            sudo yum install -y python3-venv
            python3 -m venv "${VENV_DIR}"
        else
            echo -e "${RED}Unable to install python3-venv automatically. Please install it manually and try again.${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}Virtual environment created successfully.${NC}"
else
    echo -e "${GREEN}Virtual environment already exists.${NC}"
fi

# Activate the virtual environment
echo -e "${YELLOW}Activating local venv...${NC}"
source "${VENV_DIR}/bin/activate"
echo -e "${GREEN}Local venv activated.${NC}"

# Step 2: Update pip to latest version
echo -e "${YELLOW}Updating local pip to latest version...${NC}"
pip install --upgrade pip
echo -e "${GREEN}Local pip updated successfully.${NC}"

# Step 3: Check if ansible is installed, if not install it
if ! pip show ansible &> /dev/null; then
    echo -e "${YELLOW}Ansible not found in local venv. Installing...${NC}"
    pip install ansible
    echo -e "${GREEN}Ansible installed successfully.${NC}"
else
    echo -e "${GREEN}Ansible is already installed.${NC}"
fi

# Step 4: Install other required Python packages
echo -e "${YELLOW}Installing required local venv Python packages...${NC}"
pip install jmespath

# Step 5: Check if sshpass is installed for SSH password authentication
echo -e "${YELLOW}Checking local host, if sshpass is installed for SSH password authentication...${NC}"
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}sshpass not found. Attempting to install...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y sshpass
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y sshpass
    elif command -v yum &> /dev/null; then
        sudo yum install -y sshpass
    else
        echo -e "${RED}Unable to install sshpass automatically. Please install sshpass manually.${NC}"
    fi
    
    if command -v sshpass &> /dev/null; then
        echo -e "${GREEN}sshpass installed successfully.${NC}"
    else
        echo -e "${RED}Failed to install sshpass. Please install sshpass manually.${NC}"
    fi
else
    echo -e "${GREEN}sshpass is already installed.${NC}"
fi

# Step 6: Collect parameters from user
collect_parameters

# Step 7: Run the ansible playbook
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}=== AWX Installation on REMOTE HOST ===${NC}"
echo -e "${BLUE}Running Ansible playbook...${NC}"
cd "${SCRIPT_DIR}"
# Set environment variables for Ansible
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_ROLES_PATH="${SCRIPT_DIR}/roles"
ansible-playbook -i inventories/hosts.yml site.yml

# Check if playbook execution was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Playbook executed successfully!${NC}"
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${BLUE}AWX should now be installed. Check the output above for access details.${NC}"
    echo -e "${BLUE}Remember to configure DNS or add an entry to your hosts file to access AWX via the hostname (${GREEN}$AWX_HOSTNAME${BLUE}).${NC}"
else
    echo -e "${RED}Playbook execution failed. Please check the error messages above.${NC}"
fi

# Deactivate the virtual environment
deactivate
