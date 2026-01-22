# PSUAgent-Scripts

## Install-LinuxPSUAgent.sh
> This script installs the PSUAgent as a service.  
> The service runs as the service user with minimal permissions.  
> [Official documentation for the agent](https://docs.powershelluniversal.com/config/agent#agent.json)

### Usage:
1. Download the Install-LinuxPSUAgent.sh file
2. Edit the variables in the upper part of the script
3. Make the file executable
```bash
sudo chmod +x Install-LinuxPSUAgent.sh
```
> Alternatively, the modifyed content of the file can be pasted into a terminal

### Validate:
```bash
sudo systemctl status PSUAgent # shows the status of the service
sudo journalctl -u PSUAgent --no-pager # shows logs without timestamps
```
