# Mealie - Recipe Manager

## Table of Contents
- [Overview](#overview)
- [What is Mealie?](#what-is-mealie)
- [Why Use Mealie?](#why-use-mealie)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Recipe Management  
**Docker Image:** [hkotel/mealie](https://hub.docker.com/r/hkotel/mealie)  
**Default Stack:** `productivity.yml`  
**Web UI:** `https://mealie.${DOMAIN}` or `http://SERVER_IP:9925`  
**Ports:** 9925

## What is Mealie?

Mealie is a self-hosted recipe manager and meal planner. It imports recipes from websites, manages your recipe collection, generates shopping lists, and plans meals. Beautiful UI with family sharing and mobile-friendly design.

### Key Features
- **Recipe Import:** From any website URL
- **Meal Planning:** Weekly meal calendar
- **Shopping Lists:** Auto-generated from recipes
- **Categories & Tags:** Organize recipes
- **Search:** Full-text recipe search
- **Family Sharing:** Multiple users
- **OCR:** Scan recipe cards
- **API:** Integrations possible
- **Recipe Scaling:** Adjust servings
- **Mobile Friendly:** Responsive design

## Why Use Mealie?

1. **Centralized Recipes:** All recipes in one place
2. **Import from Anywhere:** URL recipe scraping
3. **Meal Planning:** Plan weekly meals
4. **Shopping Lists:** Auto-generated
5. **Family Sharing:** Everyone can access
6. **No Ads:** Unlike recipe websites
7. **Privacy:** Your data only
8. **Free & Open Source:** No cost

## Configuration in AI-Homelab

```
/opt/stacks/productivity/mealie/data/    # Recipes, images, DB
```

## Official Resources

- **Website:** https://hay-kot.github.io/mealie
- **GitHub:** https://github.com/hay-kot/mealie
- **Documentation:** https://hay-kot.github.io/mealie/documentation/getting-started

## Docker Configuration

```yaml
mealie:
  image: hkotel/mealie:latest
  container_name: mealie
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "9925:9000"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - MAX_WORKERS=1
    - WEB_CONCURRENCY=1
    - BASE_URL=https://mealie.${DOMAIN}
  volumes:
    - /opt/stacks/productivity/mealie/data:/app/data
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.mealie.rule=Host(`mealie.${DOMAIN}`)"
    - "traefik.http.routers.mealie.entrypoints=websecure"
    - "traefik.http.routers.mealie.tls.certresolver=letsencrypt"
    - "traefik.http.services.mealie.loadbalancer.server.port=9000"
```

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d mealie
   ```

2. **Access UI:** `http://SERVER_IP:9925`

3. **Initial Login:**
   - Email: `changeme@email.com`
   - Password: `MyPassword`
   - **Change immediately!**

4. **User Settings:**
   - Change email and password
   - Set preferences

5. **Import Recipe:**
   - "+" button → Import Recipe
   - Paste website URL
   - Mealie extracts recipe automatically
   - Edit and save

6. **Meal Planning:**
   - Calendar view
   - Drag recipes to days
   - Generate shopping list

## Summary

Mealie is your digital recipe box offering:
- Recipe import from URLs
- Meal planning calendar
- Auto shopping lists
- Family sharing
- Recipe organization
- Mobile-friendly interface
- Free and open-source

**Perfect for:**
- Recipe collectors
- Meal planners
- Families
- Cooking enthusiasts
- Grocery list automation
- Recipe organization

**Key Points:**
- Import from any recipe website
- Meal calendar planning
- Shopping list generation
- Multiple users supported
- Change default credentials!
- Mobile-responsive design
- Recipe scaling feature

**Remember:**
- Change default login immediately
- Organize with categories/tags
- Use meal planner for weekly plans
- Generate shopping lists from meals
- Share with family members
- Import existing recipes from URLs

Mealie simplifies meal planning and recipe management!
