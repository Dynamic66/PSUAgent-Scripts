#!/bin/bash
# PowerShell Universal Agent installation script for Linux
# ----
# This script will install PowerShell Universal on Linux as a service
# ----
# Dependencies:
# wget
# unzip
#
# Make sure they are installed
# ----

# Agent connection settings
agent_hub="linuxHub"                 # Required, eventhub needs to be created befor running this script
agent_url="http://localhost:5000"    # Required
agent_script_path=""                 # optional
agent_description=""                 # optional
agent_token=""                       # optional

psu_version="5.6.13"                 # Change to current version
psu_arch="x64"                       # Change to desired architecture


# Download configuration
psu_file="Universal.linux-${psu_arch}.${psu_version}.zip"
psu_url="https://imsreleases.blob.core.windows.net/universal/production/${psu_version}/${psu_file}"

# Installation paths
psu_agent_path="/opt/PowerShellUniversal"
psu_agent_exec="${psu_agent_path}/PSUAgent"

# Service configuration
psu_agent_service="PSUAgent"
psu_agent_user="PSUAgent"
psu_agent_home="/home/$psu_agent_user"
psu_agent_config="${psu_agent_home}/.config/PowerShellUniversal/agent.json"
psu_service_file="/etc/systemd/system/${psu_agent_service}.service"

# Generate agent configuration JSON
read -r -d '' agent_json_config <<EOF
{
    "Connections": [
        {
            "Hub": "${agent_hub}",
            "ScriptPath": "${agent_script_path}",
            "Url": "${agent_url}",
            "Description": "${agent_description}",
            "AppToken": "${agent_token}"
        }
    ]
}
EOF

# Generate systemd service file
read -r -d '' service_config <<EOF
[Unit]
Description=PowerShell Universal Agent
After=network.target

[Service]
User=${psu_agent_user}
WorkingDirectory=${psu_agent_path}
ExecStart=${psu_agent_exec}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Installation steps
echo "Stopping ${psu_agent_service}"
sudo systemctl stop "$psu_agent_service" 2>/dev/null || true

echo "Creating ${psu_agent_path} and granting access to ${USER}"
sudo mkdir -p "$psu_agent_path"
sudo setfacl -m "u:${USER}:rwx" "$psu_agent_path"

echo "Creating user ${psu_agent_user} and setting ownership of ${psu_agent_path}"
sudo useradd -r -s /bin/false "$psu_agent_user" 2>/dev/null || echo "User ${psu_agent_user} already exists"
sudo chown "$psu_agent_user" -R "$psu_agent_path"

echo "Downloading PowerShell Universal ${psu_version} (${psu_arch})"
wget -q "$psu_url" -O "$psu_file"

echo "Extracting ${psu_file} to ${psu_agent_path}"
unzip -o -qq "$psu_file" -d "$psu_agent_path"

echo "Remove ${psu_file}"
rm psu_file

echo "Making ${psu_agent_exec} executable"
sudo chmod +x "$psu_agent_exec"

echo "Creating directory for agent configuration at ${psu_agent_config}"
mkdir -p "$(dirname "$psu_agent_config")"
chown "$psu_agent_user" "$(dirname "$psu_agent_config")"
chmod 700 "$(dirname "$psu_agent_config")"

echo "Creating and populating agent.json"
echo "$agent_json_config" | sudo tee "$psu_agent_config" > /dev/null
sudo chown "$psu_agent_user" "$psu_agent_config"
sudo chmod 600 "$psu_agent_config" #making the file only readable to the service user

echo "Registering systemd service for ${psu_agent_service}"
if [ ! -f "$psu_service_file" ]; then
    echo "$service_config" | sudo tee "$psu_service_file" > /dev/null
    echo "Service file created at ${psu_service_file}"
    sudo systemctl daemon-reload
else
    echo "Service file already exists at ${psu_service_file}"
fi

echo "Enabling ${psu_agent_service}"
sudo systemctl enable "${psu_agent_service}"

echo "Starting ${psu_agent_service}"
sudo systemctl start "${psu_agent_service}"
sudo systemctl status "${psu_agent_service}" --no-pager
