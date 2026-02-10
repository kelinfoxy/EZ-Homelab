# Arcane Configuration Guide

## After Deploying EZ-Holemlab
* Go to http://SERVER_IP:3552
* Login as arcane arcane-admin
* Change default password (prompted)
* Settings -> Users -> Create User -> Toggle on Admin
* Log out and back in as new user

## Environment Configuration

* Environments -> Environment Overview
    * Give your renvironment a name (Production, Development, server-host-name, etc.)
    * API URL: use the server's ip:port where port is 3552
    * Click Save
* General
    * Projects Directory & Disk Usage Settings
        * This is where compose files are stored
        * /opt/stacks
    * Base Server URL
        * http://server-ip (no port)
    * Click Save

## Optional Steps
* Customzation -> Templates -> Manage Registries -> Add Registry


## Installer Script (for reference only)
* run the installer script  `curl -fsSL https://getarcane.app/install.sh | sudo bash`
* Join Docker Group `sudo usermod -aG docker 1000`
* Reboot