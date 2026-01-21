#!/bin/bash

# Script to bring stacks down and back up (to reload compose file changes)
# then stop the webui containers so Sablier can control them
# leaving the databases running

stacks=(
    "arr-stack"
    "backrest"
    "bitwarden"
    "bookstack"
    "code-server"
    "dokuwiki"
    "dozzle"
    "duplicati"
    "formio"
    "gitea"
    "glances"
    "mealie"
    "mediawiki"
    "nextcloud"
    "tdarr"
    "unmanic"
    "wordpress"
)

for stack in "${stacks[@]}"; do
    if [[ "$stack" == "duplicati" || "$stack" == "formio" || "$stack" == "tdarr" ]]; then
        file="/opt/stacks/$stack/docker-compose.yml"
    else
        file="/opt/stacks/$stack/docker-compose.yaml"
    fi
    echo "Starting $stack..."
    docker compose -f "$file" stop && docker compose -f "$file" up -d
done

echo "Stopping web services to enable on-demand starting by Sablier..."
docker ps --filter "label=sablier.enable=true" --format "{{.Names}}" | xargs -r docker stop

echo "All stacks started (DBs running). Web services stopped and will be started on-demand by Sablier."
