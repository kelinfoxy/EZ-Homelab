#!/bin/bash
# Core Services Backup Script
# Run this script to backup critical configuration files and database

BACKUP_DIR="/opt/stacks/core/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="core_backup_${TIMESTAMP}"

echo "Creating backup: ${BACKUP_NAME}"

# Create backup directory
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"

# Backup Authelia configuration and database
echo "Backing up Authelia..."
cp -r /opt/stacks/core/authelia/config "${BACKUP_DIR}/${BACKUP_NAME}/"

# Backup Traefik configuration (excluding certificates for security)
echo "Backing up Traefik configuration..."
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/traefik"
cp -r /opt/stacks/core/traefik/config "${BACKUP_DIR}/${BACKUP_NAME}/traefik/"
cp -r /opt/stacks/core/traefik/dynamic "${BACKUP_DIR}/${BACKUP_NAME}/traefik/"
# Note: letsencrypt/acme.json contains private keys - backup separately if needed

# Backup docker-compose.yml
echo "Backing up docker-compose.yml..."
cp /opt/stacks/core/docker-compose.yml "${BACKUP_DIR}/${BACKUP_NAME}/"

# Backup environment file (contains sensitive data - handle carefully)
echo "Backing up .env file..."
cp /opt/stacks/core/.env "${BACKUP_DIR}/${BACKUP_NAME}/"

# Create archive
echo "Creating compressed archive..."
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"

# Cleanup uncompressed backup
rm -rf "${BACKUP_NAME}"

echo "Backup completed: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)"

# Keep only last 10 backups
echo "Cleaning up old backups..."
ls -t "${BACKUP_DIR}"/*.tar.gz | tail -n +11 | xargs -r rm -f

echo "Backup script completed successfully"