# AI-Homelab Setup Scripts

## setup-homelab.sh

Automated first-run setup script for preparing a fresh Debian installation for AI-Homelab deployment.

### What It Does

1. **System Update** - Updates all system packages
2. **Install Dependencies** - Installs required packages (curl, git, etc.)
3. **Install Docker** - Adds Docker repository and installs Docker Engine with Compose V2
4. **Configure User Groups** - Adds user to sudo and docker groups
5. **Configure SSH** - Enables and starts SSH server for remote access
6. **Detect NVIDIA GPU** - Checks for NVIDIA graphics card and provides manual driver installation instructions
7. **Create Directories** - Sets up `/opt/stacks`, `/opt/dockge`, `/mnt/media`, `/mnt/downloads`
8. **Create Docker Networks** - Creates homelab-network, traefik-network, and media-network

### Usage

```bash
# Download the repository
git clone https://github.com/kelinfoxy/AI-Homelab.git
cd AI-Homelab

# Make the script executable (if needed)
chmod +x scripts/setup-homelab.sh

# Run with sudo
sudo ./scripts/setup-homelab.sh
```

### After Running

1. Log out and log back in for group changes to take effect
2. Edit `.env` file with your configuration
3. Deploy the core infrastructure stack
4. Deploy the infrastructure stack (includes Dockge)
5. Access Dockge to manage remaining stacks

### NVIDIA GPU Support

If an NVIDIA GPU is detected, the script will provide instructions for manual driver installation:

1. Identify your GPU model from the output
2. Visit https://www.nvidia.com/Download/index.aspx
3. Download the official driver for your GPU
4. Run the installer: `sudo bash NVIDIA-Linux-x86_64-XXX.XX.run`
5. Install container toolkit:
   ```bash
   sudo apt-get install -y nvidia-container-toolkit
   sudo nvidia-ctk runtime configure --runtime=docker
   sudo systemctl restart docker
   ```

This manual approach avoids driver conflicts that often occur with automated installation methods.

### Requirements

- Fresh Debian installation (Debian 11 or 12)
- Root access (via sudo)
- Internet connection

### Tested On

- Debian 11 (Bullseye)
- Debian 12 (Bookworm)

### Notes

- The script is idempotent - safe to run multiple times
- Creates directories with proper ownership
- Configures Docker networks automatically
- SSH is enabled for remote management
- NVIDIA driver installation requires manual intervention for reliability
