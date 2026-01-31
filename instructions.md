# Manual installation

```bash
sudo apt update && sudo apt upgrade -y && sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
sudo curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
sudo usermod -aG sudo $USER

# Log out and back in, or run: newgrp docker

cd ~
git clone https://github.com/kelinfoxy/AI-Homelab.git
cd AI-Homelab
cp .env.example .env
nano .env  # Edit all required variables

sudo mkdir -p /opt/stacks /mnt/{media,database,downloads,backups}
sudo chown -R $USER:$USER /opt/stacks /mnt
docker network create traefik-network
docker network create homelab-network
docker network create dockerproxy-network
docker network create media-network

# Deploy 
sudo mkdir -p /opt/stacks/core
sudo cp docker-compose/core/docker-compose.yml /opt/stacks/core/docker-compose.yml
sudo cp -r config-templates/traefik /opt/stacks/core/
sudo cp .env /opt/stacks/core/
sudo mkdir -p /opt/stacks/infrastructure
sudo cp docker-compose/infrastructure/docker-compose.yml /opt/stacks/infrastructure/docker-compose.yml
sudo cp .env /opt/stacks/infrastructure/
sudo mkdir -p /opt/stacks/dashboards
sudo cp docker-compose/dashboards/docker-compose.yml /opt/stacks/dashboards/docker-compose.yml
sudo cp -r config-templates/homepage /opt/stacks/dashboards/
sudo cp .env /opt/stacks/dashboards/
mkdir -p /opt/stacks/core/authelia
sudo cp config-templates/authelia/* /opt/stacks/core/authelia/

# Generate password hash (takes 30-60 seconds)
docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password 'YourSecurePassword'


# Edit users_database.yml
nano /opt/stacks/core/authelia/users_database.yml

# Replace password hash and email in the users section:
users:
  admin:
    displayname: "Admin User"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."  # Your hash here
    email: your.email@example.com
    groups:
      - admins
      - users

# Update Traefik email
sed -i "s/admin@example.com/$ACME_EMAIL/" /opt/stacks/core/traefik/traefik.yml

# Replace Homepage domain variables
find /opt/stacks/dashboards/homepage -type f \( -name "*.yaml" -o -name "*.yml" \) -exec sed -i "s/{{HOMEPAGE_VAR_DOMAIN}}/$DOMAIN/g" {} \;

cd /opt/stacks/core
docker compose up -d

cd /opt/stacks/infrastructure
docker compose up -d

cd /opt/stacks/dashboards
docker compose up -d


















```

