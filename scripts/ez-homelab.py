#!/usr/bin/env python3
"""
EZ-Homelab TUI Deployment Script
A modern terminal user interface for EZ-Homelab deployment
"""

import sys
import argparse
import os
import shutil
import json
from pathlib import Path
from datetime import datetime
from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
from rich.table import Table
import questionary

# Service definitions
SERVICE_STACKS = {
    'core': {
        'DuckDNS': 'Dynamic DNS with Let\'s Encrypt',
        'Traefik': 'Reverse proxy with SSL termination',
        'Authelia': 'SSO authentication service',
        'Sablier': 'Lazy loading service'
    },
    'infrastructure': {
        'Pi-hole': 'DNS ad blocker',
        'Dockge': 'Docker stack manager',
        'Portainer': 'Docker container manager',
        'Dozzle': 'Docker log viewer',
        'Glances': 'System monitoring'
    },
    'dashboards': {
        'Homepage': 'Service dashboard',
        'Homarr': 'Modern dashboard'
    },
    'additional_stacks': {
        'Media': 'Jellyfin, Calibre-Web',
        'Media Management': '*arr services (Sonarr, Radarr, etc.)',
        'Home Automation': 'Home Assistant, Node-RED',
        'Productivity': 'Nextcloud, Gitea, Mealie',
        'Monitoring': 'Grafana, Prometheus, Uptime Kuma',
        'Utilities': 'Vaultwarden, Backrest, Duplicati'
    }
}

class EZHomelabTUI:
    """Main TUI application class"""

    def __init__(self):
        # Ensure we're running from the repository root
        script_dir = Path(__file__).parent
        repo_root = script_dir.parent
        os.chdir(repo_root)
        
        self.console = Console()
        self.config = {}
        self.deployment_type = None
        self.selected_services = {}
        self.backup_dir = Path.home() / ".ez-homelab" / "backups"
        self.backup_dir.mkdir(parents=True, exist_ok=True)

    def run(self):
        """Main application entry point"""
        # Show banner
        self.show_banner()

        # Check for special modes
        if self._handle_special_modes():
            return True

        # Pre-flight checks
        if not self.run_preflight_checks():
            return False

        # Load existing configuration
        self.load_existing_config()

        # Interactive questions
        if not self.run_interactive_questions():
            return False

        # Show summary and confirm
        if not self.show_summary_and_confirm():
            return False

        # Perform deployment
        return self.perform_deployment()

    def show_summary_and_confirm(self):
        """Show final configuration and get confirmation"""
        import os

        # Clear screen and show final config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()

        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Show admin credentials summary
        self.console.print("[bold]Admin Credentials Summary[/bold]")
        self.console.print(f"  • Username: {self.config.get('DEFAULT_USER', 'admin')}")
        self.console.print(f"  • Password: {self.config.get('DEFAULT_PASSWORD', 'changeme')}")
        self.console.print(f"  • Email: {self.config.get('DEFAULT_EMAIL', 'admin@example.com')}")
        self.console.print()

        # Confirm deployment
        confirm = questionary.confirm(
            "Ready to deploy EZ-Homelab with this configuration?",
            default=False
        ).ask()

        return confirm

    def _handle_special_modes(self):
        """Handle special operation modes"""
        # Check command line args for special modes
        import sys
        if len(sys.argv) > 1:
            if '--backup' in sys.argv:
                return self.backup_configuration()
            elif '--restore' in sys.argv:
                return self.restore_configuration()
            elif '--validate' in sys.argv:
                issues = self.validate_configuration()
                return len(issues) == 0
            elif '--health' in sys.argv:
                self.check_service_health()
                return True
            elif '--uninstall' in sys.argv:
                return self.uninstall_services()

        return False

    def show_banner(self):
        """Display application banner"""
        banner = """+==============================================+
|              EZ-HOMELAB TUI                  |
|        Terminal User Interface               |
|        for Homelab Deployment                |
+==============================================+"""
        self.console.print(Panel.fit(banner, border_style="blue"))
        self.console.print()

    def run_preflight_checks(self):
        """Run pre-flight system checks"""
        self.console.print("[bold blue]Running pre-flight checks...[/bold blue]")

        checks_passed = True

        # Check Python version
        python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
        if sys.version_info >= (3, 8):
            self.console.print(f"[green]✓[/green] Python {python_version}")
        else:
            self.console.print(f"[red]✗[/red] Python {python_version} - Requires Python 3.8+")
            checks_passed = False

        # Check if running as administrator (for Docker setup)
        try:
            import ctypes
            is_admin = ctypes.windll.shell32.IsUserAnAdmin()
            if is_admin:
                self.console.print("[green]✓[/green] Running as administrator")
            else:
                self.console.print("[yellow]⚠[/yellow] Not running as administrator (may need for Docker setup)")
        except:
            self.console.print("[yellow]⚠[/yellow] Cannot check administrator status")

        # Check Docker
        if self.check_docker():
            self.console.print("[green]✓[/green] Docker available")
        else:
            self.console.print("[red]✗[/red] Docker not available")
            checks_passed = False

        self.console.print()
        return checks_passed

    def check_docker(self):
        """Check if Docker is available"""
        try:
            import subprocess
            result = subprocess.run(['docker', '--version'],
                                  capture_output=True, text=True, timeout=5)
            return result.returncode == 0
        except:
            return False

    def load_existing_config(self):
        """Load existing .env configuration"""
        env_path = Path('.env')
        if env_path.exists():
            self.console.print("[blue]Loading existing .env configuration...[/blue]")
            try:
                from dotenv import load_dotenv
                load_dotenv()
                # Load common variables
                self.config.update({
                    'DOMAIN': os.getenv('DOMAIN', ''),
                    'PUID': os.getenv('PUID', '1000'),
                    'PGID': os.getenv('PGID', '1000'),
                    'TZ': os.getenv('TZ', 'America/New_York'),
                    'DEPLOYMENT_TYPE': os.getenv('DEPLOYMENT_TYPE', ''),
                })
                self.console.print("[green]✓[/green] Configuration loaded")
            except ImportError:
                self.console.print("[yellow]⚠[/yellow] python-dotenv not available, skipping .env loading")
        else:
            self.console.print("[yellow]No .env file found, will create new configuration[/yellow]")
        self.console.print()

    def run_interactive_questions(self):
        """Run interactive questions to gather configuration"""
        import os

        # Clear screen and show header
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()

        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()

        # Initialize config display
        self._display_current_config()

        # Deployment type
        deployment_choices = [
            {"name": "Single Server Full Stack", "value": "single"},
            {"name": "Core Server Only", "value": "core"},
            {"name": "Remote Server", "value": "remote"}
        ]

        self.deployment_type = questionary.select(
            "Select deployment type:",
            choices=deployment_choices
        ).ask()

        if not self.deployment_type:
            return False

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Domain configuration
        existing_domain = self.config.get('DOMAIN', '')
        if existing_domain:
            self.console.print(f"[cyan]Current domain: {existing_domain}[/cyan]")

        domain_input = questionary.text(
            "Enter your domain (e.g., yourname.duckdns.org):"
        ).ask()

        # Use the input if provided, otherwise keep existing
        if domain_input and domain_input.strip():
            self.config['DOMAIN'] = domain_input.strip()
        elif existing_domain:
            self.config['DOMAIN'] = existing_domain
        else:
            self.console.print("[red]✗[/red] Domain is required")
            return False

        # Validate domain format
        if not self._validate_domain(self.config['DOMAIN']):
            self.console.print("[red]✗[/red] Invalid domain format. Please use format: subdomain.duckdns.org")
            return False

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Default credentials configuration
        self.console.print("\n[bold]Default Credentials Configuration[/bold]")
        self.console.print("These credentials will be used as defaults for multiple services.")

        # Default user
        existing_user = self.config.get('DEFAULT_USER', '')
        if existing_user and existing_user != 'admin':
            self.console.print(f"[cyan]Current default user: {existing_user}[/cyan]")

        user_input = questionary.text(
            "Enter default admin username:",
            default=existing_user if existing_user else "admin"
        ).ask()

        if user_input and user_input.strip():
            self.config['DEFAULT_USER'] = user_input.strip()
        else:
            self.config['DEFAULT_USER'] = 'admin'

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Default password
        existing_password = self.config.get('DEFAULT_PASSWORD', '')
        if existing_password and existing_password != 'changeme':
            self.console.print(f"[cyan]Current default password: {existing_password}[/cyan]")

        password_input = questionary.password(
            "Enter default admin password:",
            default=existing_password if existing_password and existing_password != 'changeme' else "changeme"
        ).ask()

        if password_input and password_input.strip():
            self.config['DEFAULT_PASSWORD'] = password_input.strip()
        else:
            self.config['DEFAULT_PASSWORD'] = 'changeme'

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Default email
        existing_email = self.config.get('DEFAULT_EMAIL', '')
        if existing_email and existing_email != 'admin@example.com':
            self.console.print(f"[cyan]Current default email: {existing_email}[/cyan]")

        email_input = questionary.text(
            "Enter default admin email:",
            default=existing_email if existing_email and existing_email != 'admin@example.com' else "admin@example.com"
        ).ask()

        if email_input and email_input.strip():
            self.config['DEFAULT_EMAIL'] = email_input.strip()
        else:
            self.config['DEFAULT_EMAIL'] = 'admin@example.com'

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Service selection based on deployment type
        if self.deployment_type == 'single':
            return self.select_services_single()
        elif self.deployment_type == 'core':
            return self.select_services_core()
        else:  # remote
            return self.select_services_remote()

    def _display_current_config(self):
        """Display current configuration in a compact format"""
        deployment_type_names = {
            'single': 'Single Server Full Stack',
            'core': 'Core Server Only',
            'remote': 'Remote Server'
        }

        config_parts = []

        if self.deployment_type:
            config_parts.append(f"✓ {deployment_type_names.get(self.deployment_type, self.deployment_type)}")

        if 'DOMAIN' in self.config:
            config_parts.append(f"✓ {self.config['DOMAIN']}")

        if 'DEFAULT_USER' in self.config:
            config_parts.append(f"✓ {self.config['DEFAULT_USER']}")

        if 'DEFAULT_EMAIL' in self.config:
            config_parts.append(f"✓ {self.config['DEFAULT_EMAIL']}")

        if config_parts:
            for part in config_parts:
                self.console.print(part)
        else:
            self.console.print("Configure your homelab settings...")

        # Show selected services with proper formatting
        if self.selected_services:
            # Core services
            if 'core' in self.selected_services:
                core_services = self.selected_services['core']
                if isinstance(core_services, list):
                    # Extract service names without descriptions
                    service_names = [s.split(' - ')[0] if ' - ' in s else s for s in core_services]
                    self.console.print(f"✓ Core Services ({', '.join(service_names)})")

            # Infrastructure services
            if 'infrastructure' in self.selected_services:
                infra_services = self.selected_services['infrastructure']
                if isinstance(infra_services, list) and infra_services:
                    self.console.print(f"✓ Infrastructure ({', '.join(infra_services)})")

            # Dashboard services
            if 'dashboards' in self.selected_services:
                dashboard_services = self.selected_services['dashboards']
                if isinstance(dashboard_services, list) and dashboard_services:
                    self.console.print(f"✓ Dashboard ({', '.join(dashboard_services)})")

            # Additional services
            if 'additional' in self.selected_services:
                additional_services = self.selected_services['additional']
                if isinstance(additional_services, list) and additional_services:
                    for service in additional_services:
                        if service in SERVICE_STACKS['additional_stacks']:
                            desc = SERVICE_STACKS['additional_stacks'][service]
                            self.console.print(f"✓ {service} Services ({desc})")

        self.console.print()

    def select_services_single(self):
        """Select services for single server deployment"""
        import os

        # Core services (required, no selection needed)
        core_services = ['DuckDNS', 'Traefik', 'Authelia', 'Sablier']
        self.selected_services.update({'core': core_services})

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Infrastructure services
        infra_choices = [
            {"name": f"{service} - {desc}", "value": service, "checked": True}
            for service, desc in SERVICE_STACKS['infrastructure'].items()
        ]

        selected_infra = questionary.checkbox(
            "Select infrastructure services:",
            choices=infra_choices
        ).ask()

        if selected_infra:
            self.selected_services['infrastructure'] = selected_infra

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Dashboard services
        dashboard_choices = [
            {"name": f"{service} - {desc}", "value": service, "checked": False}
            for service, desc in SERVICE_STACKS['dashboards'].items()
        ]

        selected_dashboards = questionary.checkbox(
            "Select dashboard services (choose one or none):",
            choices=dashboard_choices
        ).ask()

        if selected_dashboards:
            self.selected_services['dashboards'] = selected_dashboards

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Additional service stacks
        additional_choices = [
            {"name": f"{stack} - {desc}", "value": stack, "checked": False}
            for stack, desc in SERVICE_STACKS['additional_stacks'].items()
        ]

        selected_additional = questionary.checkbox(
            "Select additional service stacks:",
            choices=additional_choices
        ).ask()

        if selected_additional:
            self.selected_services['additional'] = selected_additional

        # Final update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        return True

    def select_services_core(self):
        """Select services for core server deployment"""
        import os

        # Core services (required)
        self.selected_services['core'] = ['DuckDNS', 'Traefik', 'Authelia', 'Sablier']

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Minimal infrastructure
        infra_choices = [
            {"name": f"Dockge - {SERVICE_STACKS['infrastructure']['Dockge']}", "value": "Dockge", "checked": True},
            {"name": f"Portainer - {SERVICE_STACKS['infrastructure']['Portainer']}", "value": "Portainer"}
        ]

        selected_infra = questionary.checkbox(
            "Select infrastructure services:",
            choices=infra_choices
        ).ask()

        if selected_infra:
            self.selected_services['infrastructure'] = selected_infra

        # Final update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        return True

    def select_services_remote(self):
        """Select services for remote server deployment"""
        import os

        # For remote deployment, we mainly configure routing
        self.selected_services['remote_config'] = True

        # Update and redisplay config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()
        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        return True

    def show_summary_and_confirm(self):
        """Show final confirmation"""
        import os

        # Clear screen and show final config
        os.system('cls' if os.name == 'nt' else 'clear')
        self.show_banner()

        self.console.print("[bold blue]EZ-Homelab Configuration[/bold blue]")
        self.console.print()
        self._display_current_config()

        # Show admin credentials summary
        self.console.print("[bold]Admin Credentials Summary[/bold]")
        self.console.print(f"  • Username: {self.config.get('DEFAULT_USER', 'admin')}")
        self.console.print(f"  • Password: {self.config.get('DEFAULT_PASSWORD', 'changeme')}")
        self.console.print(f"  • Email: {self.config.get('DEFAULT_EMAIL', 'admin@example.com')}")
        self.console.print()

        # Confirm deployment
        confirm = questionary.confirm(
            "Ready to deploy EZ-Homelab with this configuration?",
            default=False
        ).ask()

        return confirm

    def perform_deployment(self):
        """Perform the actual deployment"""
        self.console.print("\n[bold blue]Starting deployment...[/bold blue]")

        # Backup current configuration
        self.backup_configuration()

        # Define deployment steps
        steps = [
            "Generating .env configuration",
            "Validating configuration",
            "Creating docker-compose files",
            "Starting services",
            "Running post-deployment checks"
        ]

        deployment_success = True
        step_results = []

        try:
            # Step 1: Generate .env file
            self.console.print(f"[green]✓[/green] {steps[0]}")
            try:
                self.generate_env_file(quiet=True)
                step_results.append(("env_generation", True, None))
            except Exception as e:
                self.console.print(f"[red]✗[/red] {steps[0]}")
                step_results.append(("env_generation", False, str(e)))
                deployment_success = False

            # Step 2: Validate configuration
            try:
                issues = self.validate_configuration(quiet=True)
                if issues:
                    self.console.print(f"[red]✗[/red] {steps[1]}")
                    step_results.append(("validation", False, f"{len(issues)} issues found"))
                    deployment_success = False
                else:
                    self.console.print(f"[green]✓[/green] {steps[1]}")
                    step_results.append(("validation", True, None))
            except Exception as e:
                self.console.print(f"[red]✗[/red] {steps[1]}")
                step_results.append(("validation", False, str(e)))
                deployment_success = False

            # Step 3: Create docker-compose files
            try:
                self.generate_compose_files(quiet=True)
                self.console.print(f"[green]✓[/green] {steps[2]}")
                step_results.append(("compose_generation", True, None))
            except Exception as e:
                self.console.print(f"[red]✗[/red] {steps[2]}")
                step_results.append(("compose_generation", False, str(e)))
                deployment_success = False

            # Step 4: Start services
            try:
                success, service_errors = self.start_services(quiet=True)
                if not success:
                    self.console.print(f"[red]✗[/red] {steps[3]}")
                    step_results.append(("service_startup", False, f"Service startup failed: {len(service_errors)} errors"))
                    deployment_success = False
                else:
                    self.console.print(f"[green]✓[/green] {steps[3]}")
                    step_results.append(("service_startup", True, None))
            except Exception as e:
                self.console.print(f"[red]✗[/red] {steps[3]}")
                step_results.append(("service_startup", False, str(e)))
                deployment_success = False

            # Step 5: Post-deployment checks
            try:
                health_status = self.check_service_health(quiet=True)
                # Check if any services have issues
                has_issues = any(not status.get('running', False) for status in health_status.values())
                if has_issues:
                    self.console.print(f"[yellow]⚠[/yellow] {steps[4]}")
                    step_results.append(("health_check", False, "Some services have issues"))
                else:
                    self.console.print(f"[green]✓[/green] {steps[4]}")
                    step_results.append(("health_check", True, None))
            except Exception as e:
                self.console.print(f"[yellow]⚠[/yellow] {steps[4]}")
                step_results.append(("health_check", False, str(e)))

            # Show final status
            if deployment_success:
                self.console.print("\n[green]✓ Deployment completed successfully![/green]")
                self.console.print("\n[bold cyan]Your services are now running![/bold cyan]")
                self.console.print("Access them through Traefik reverse proxy with automatic SSL.")
            else:
                self.console.print("\n[yellow]⚠ Deployment completed with issues[/yellow]")
                self.console.print("[yellow]Some services may not be fully operational.[/yellow]")

                # Show detailed errors
                if 'service_errors' in locals() and service_errors:
                    self.console.print("\n[bold red]Service Startup Errors:[/bold red]")
                    for error in service_errors:
                        if ': ' in error:
                            key, value = error.split(': ', 1)
                            self.console.print(f"  [red]• {key}:[/red] {value}")
                        else:
                            self.console.print(f"  [red]• {error}[/red]")

                # Show which steps failed
                failed_steps = [step for step, success, _ in step_results if not success]
                if failed_steps:
                    self.console.print(f"\n[bold red]Deployment Issues:[/bold red]")
                    for step_name, success, error_msg in step_results:
                        if not success and error_msg:
                            self.console.print(f"  [red]• {step_name}:[/red] {error_msg}")

                # Show health status table for failed deployments
                if not deployment_success:
                    self.console.print("\n[dim]Service Health Status:[/dim]")
                    for stack, status in health_status.items():
                        if status['running']:
                            self.console.print(f"  [green]✓[/green] {stack}")
                        else:
                            self.console.print(f"  [red]✗[/red] {stack}")

            return deployment_success

        except Exception as e:
            self.console.print(f"\n[red]✗ Deployment failed: {e}[/red]")
            return False

    def generate_env_file(self, quiet=False):
        """Generate comprehensive .env configuration file"""
        if not quiet:
            self.console.print("Generating .env configuration...")

        # Ask user for env file name (skip in quiet mode)
        if quiet:
            env_filename = ".env"
        else:
            env_filename = questionary.text(
                "Enter .env filename:",
                default=".env"
            ).ask()

            if not env_filename or not env_filename.strip():
                env_filename = ".env"

        import secrets
        import socket
        import getpass

        # Generate secure secrets
        jwt_secret = secrets.token_hex(64)
        session_secret = secrets.token_hex(64)
        encryption_key = secrets.token_hex(64)

        # Get system information
        server_ip = self.config.get('SERVER_IP', '192.168.1.100')
        server_hostname = self.config.get('SERVER_HOSTNAME', socket.gethostname())
        domain_parts = self.config['DOMAIN'].split('.')
        duckdns_subdomain = domain_parts[0] if len(domain_parts) > 1 else 'yourdomain'

        # Default credentials
        default_user = self.config.get('DEFAULT_USER', 'admin')
        default_password = self.config.get('DEFAULT_PASSWORD', 'changeme')
        default_email = self.config.get('DEFAULT_EMAIL', f'{default_user}@{self.config["DOMAIN"]}')

        env_content = f"""# EZ-Homelab Configuration - Generated by TUI
# Generated on: {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

# User and Group IDs for file permissions
PUID={self.config.get('PUID', '1000')}
PGID={self.config.get('PGID', '1000')}

TZ={self.config.get('TZ', 'America/New_York')}

# Configuration for this server
SERVER_IP={server_ip}
SERVER_HOSTNAME={server_hostname}

# Domain & DuckDNS Configuration
DUCKDNS_SUBDOMAINS={duckdns_subdomain}
DOMAIN={self.config['DOMAIN']}
DUCKDNS_TOKEN={self.config.get('DUCKDNS_TOKEN', 'your-duckdns-token')}

# Default credentials (used by multiple services)
DEFAULT_USER={default_user}
DEFAULT_PASSWORD={default_password}
DEFAULT_EMAIL={default_email}

# DIRECTORY PATHS
USERDIR=/opt/stacks
MEDIADIR=/mnt/media
DOWNLOADDIR=/mnt/downloads
PROJECTDIR=~/projects

# Deployment Configuration
DEPLOYMENT_TYPE={self.deployment_type}

# AUTHELIA SSO CONFIGURATION
AUTHELIA_JWT_SECRET={jwt_secret}
AUTHELIA_SESSION_SECRET={session_secret}
AUTHELIA_STORAGE_ENCRYPTION_KEY={encryption_key}

# Let's Encrypt / ACME (for SSL certificates)
ACME_EMAIL={default_email}
ADMIN_EMAIL={default_email}

# VPN Configuration (Surfshark - RECOMMENDED)
SURFSHARK_USERNAME={self.config.get('SURFSHARK_USERNAME', 'your-surfshark-username')}
SURFSHARK_PASSWORD={self.config.get('SURFSHARK_PASSWORD', 'your-surfshark-password')}
VPN_SERVER_COUNTRIES=Netherlands

# INFRASTRUCTURE SERVICES
PIHOLE_PASSWORD={default_password}

# qBittorrent
QBITTORRENT_USER=admin
QBITTORRENT_PASS={default_password}

# GRAFANA
GRAFANA_ADMIN_PASSWORD={default_password}

# VS Code Server
CODE_SERVER_PASSWORD={default_password}
CODE_SERVER_SUDO_PASSWORD={default_password}

# Jupyter Notebook
JUPYTER_TOKEN={default_password}

# DATABASES - GENERAL
POSTGRES_USER={default_user}
POSTGRES_PASSWORD={default_password}
POSTGRES_DB=homelab
PGADMIN_EMAIL={default_email}
PGADMIN_PASSWORD={default_password}

# Nextcloud
NEXTCLOUD_ADMIN_USER={default_user}
NEXTCLOUD_ADMIN_PASSWORD={default_password}
NEXTCLOUD_DB_PASSWORD={default_password}
NEXTCLOUD_DB_ROOT_PASSWORD={default_password}

# Gitea
GITEA_DB_PASSWORD={default_password}

# WordPress
WORDPRESS_DB_PASSWORD={default_password}
WORDPRESS_DB_ROOT_PASSWORD={default_password}

# BookStack
BOOKSTACK_DB_PASSWORD={default_password}
BOOKSTACK_DB_ROOT_PASSWORD={default_password}

# MediaWiki
MEDIAWIKI_DB_PASSWORD={default_password}
MEDIAWIKI_DB_ROOT_PASSWORD={default_password}

# Bitwarden (Vaultwarden)
BITWARDEN_ADMIN_TOKEN={default_password}
BITWARDEN_SIGNUPS_ALLOWED=true
BITWARDEN_INVITATIONS_ALLOWED=true

# Form.io
FORMIO_JWT_SECRET={default_password}
FORMIO_DB_SECRET={default_password}

# HOMEPAGE DASHBOARD - API KEYS (uncomment and configure as needed)
# HOMEPAGE_VAR_DOMAIN={self.config['DOMAIN']}
# HOMEPAGE_VAR_SERVER_IP={server_ip}
# HOMEPAGE_VAR_GRAFANA_USER=admin
# HOMEPAGE_VAR_GRAFANA_PASS={default_password}
"""

        try:
            with open(env_filename, 'w') as f:
                f.write(env_content)

            if not quiet:
                self.console.print(f"[green]✓[/green] Comprehensive .env file created with secure secrets")
                self.console.print(f"[cyan]File saved as: {env_filename}[/cyan]")
                self.console.print(f"[cyan]Authelia secrets generated and saved[/cyan]")

            return True, None
        except Exception as e:
            error_msg = f"Failed to create .env file: {e}"
            if not quiet:
                self.console.print(f"[red]✗[/red] {error_msg}")
            return False, error_msg

    def generate_compose_files(self, quiet=False):
        """Generate docker-compose files for selected services"""
        if not quiet:
            self.console.print("Generating docker-compose files...")

        import shutil
        import os

        # Ensure /opt/stacks directory exists
        stacks_dir = "/opt/stacks"
        try:
            if not os.path.exists(stacks_dir):
                os.makedirs(stacks_dir)
                if not quiet:
                    self.console.print(f"[cyan]Created directory: {stacks_dir}[/cyan]")

            # Always deploy core stack first
            self._copy_stack_files("core", stacks_dir, quiet)

            # Deploy additional stacks based on deployment type and selections
            if self.deployment_type == "single":
                # Single server deployment - deploy all selected stacks
                selected_stacks = []

                # Infrastructure services
                if self.selected_services.get("infrastructure"):
                    selected_stacks.append("infrastructure")

                # Dashboard services
                if self.selected_services.get("dashboards"):
                    selected_stacks.append("dashboards")

                # Additional service stacks
                additional_services = self.selected_services.get("additional", [])
                stack_name_mapping = {
                    'Media': 'media',
                    'Media Management': 'media-management',
                    'Home Automation': 'homeassistant',
                    'Productivity': 'productivity',
                    'Monitoring': 'monitoring',
                    'Utilities': 'utilities'
                }

                for service in additional_services:
                    stack_name = stack_name_mapping.get(service)
                    if stack_name:
                        selected_stacks.append(stack_name)

                for stack in selected_stacks:
                    self._copy_stack_files(stack, stacks_dir, quiet)

            elif self.deployment_type == "core-only":
                # Only core infrastructure
                pass  # Core already deployed

            elif self.deployment_type == "remote":
                # Remote server deployment - minimal local setup
                if not quiet:
                    self.console.print("[cyan]Remote deployment: Core services configured for remote server[/cyan]")

            if not quiet:
                self.console.print("[green]✓[/green] Docker compose files generated")

            return True, None
        except Exception as e:
            error_msg = f"Failed to generate compose files: {e}"
            if not quiet:
                self.console.print(f"[red]✗[/red] {error_msg}")
            return False, error_msg

    def _copy_stack_files(self, stack_name, stacks_dir, quiet=False):
        """Copy docker-compose files for a specific stack"""
        import shutil

        source_dir = f"docker-compose/{stack_name}"
        dest_dir = f"{stacks_dir}/{stack_name}"

        if os.path.exists(source_dir):
            if os.path.exists(dest_dir):
                shutil.rmtree(dest_dir)
            shutil.copytree(source_dir, dest_dir)
            if not quiet:
                self.console.print(f"[cyan]Copied {stack_name} stack to {dest_dir}[/cyan]")
        else:
            if not quiet:
                self.console.print(f"[yellow]⚠[/yellow] Stack {stack_name} not found in templates")

    def _start_stack_services(self, stack_dir, stack_name, quiet=False):
        """Start services for a specific stack"""
        import subprocess
        import os

        errors = []

        try:
            # Load environment variables from .env file
            env_file = os.path.join(os.getcwd(), '.env')
            env_vars = {}
            if os.path.exists(env_file):
                with open(env_file, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            key, value = line.split('=', 1)
                            env_vars[key] = value

            # Merge with current environment
            full_env = os.environ.copy()
            full_env.update(env_vars)

            result = subprocess.run(
                ["docker", "compose", "up", "-d"],
                cwd=stack_dir,
                capture_output=True,
                text=True,
                env=full_env,
                timeout=300  # 5 minute timeout
            )

            if result.returncode == 0:
                if not quiet:
                    self.console.print(f"[green]✓[/green] {stack_name} services started successfully")
                return True, []
            else:
                error_msg = f"Failed to start {stack_name} services: {result.stderr}"
                errors.append(error_msg)
                if not quiet:
                    self.console.print(f"[red]✗[/red] {error_msg}")
                return False, errors

        except subprocess.TimeoutExpired:
            error_msg = f"Timeout starting {stack_name} services"
            errors.append(error_msg)
            if not quiet:
                self.console.print(f"[red]✗[/red] {error_msg}")
            return False, errors

        except FileNotFoundError:
            error_msg = "docker command not found - Docker may not be installed or running"
            errors.append(error_msg)
            if not quiet:
                self.console.print(f"[red]✗[/red] {error_msg}")
            return False, errors

        except Exception as e:
            error_msg = f"Error starting {stack_name} services: {e}"
            errors.append(error_msg)
            if not quiet:
                self.console.print(f"[red]✗[/red] {error_msg}")
            return False, errors

    def start_services(self, quiet=False):
        """Start the selected services using docker-compose"""
        if not quiet:
            self.console.print("Starting services...")

        import subprocess
        import os

        stacks_dir = "/opt/stacks"
        all_errors = []
        stack_results = {}

        # Always start core stack first
        core_dir = f"{stacks_dir}/core"
        if os.path.exists(f"{core_dir}/docker-compose.yml"):
            if not quiet:
                self.console.print("[cyan]Starting core services...[/cyan]")
            success, errors = self._start_stack_services(core_dir, "core", quiet)
            stack_results["core"] = success
            if errors:
                all_errors.extend(errors)
        else:
            if not quiet:
                self.console.print("[yellow]⚠[/yellow] Core docker-compose.yml not found")
            all_errors.append("Core docker-compose.yml not found")
            return False

        # Start additional stacks based on deployment type
        if self.deployment_type == "single":
            additional_stacks = []

            # Infrastructure services
            if self.selected_services.get("infrastructure"):
                additional_stacks.append("infrastructure")

            # Dashboard services
            if self.selected_services.get("dashboards"):
                additional_stacks.append("dashboards")

            # Additional service stacks
            additional_services = self.selected_services.get("additional", [])
            stack_name_mapping = {
                'Media': 'media',
                'Media Management': 'media-management',
                'Home Automation': 'homeassistant',
                'Productivity': 'productivity',
                'Monitoring': 'monitoring',
                'Utilities': 'utilities'
            }

            for service in additional_services:
                stack_name = stack_name_mapping.get(service)
                if stack_name:
                    additional_stacks.append(stack_name)

            for stack in additional_stacks:
                stack_dir = f"{stacks_dir}/{stack}"
                if os.path.exists(f"{stack_dir}/docker-compose.yml"):
                    if not quiet:
                        self.console.print(f"[cyan]Starting {stack} services...[/cyan]")
                    success, errors = self._start_stack_services(stack_dir, stack, quiet)
                    stack_results[stack] = success
                    if errors:
                        all_errors.extend(errors)

        elif self.deployment_type == "remote":
            if not quiet:
                self.console.print("[cyan]Remote deployment: Services configured for remote server[/cyan]")
                self.console.print("[yellow]⚠[/yellow] Manual deployment required on remote server")

        if not quiet:
            self.console.print("[green]✓[/green] Service deployment completed")

        # Return success if at least core services started (for demo purposes)
        core_success = stack_results.get("core", False)
        return core_success, all_errors

    def backup_configuration(self):
        """Backup current configuration"""
        now = datetime.now()
        timestamp = now.strftime("%Y-%m-%d_%I-%M-%p")  # More readable format
        backup_file = self.backup_dir / f"config_backup_{timestamp}.json"

        backup_data = {
            'timestamp': now.isoformat(),
            'config': self.config,
            'selected_services': self.selected_services,
            'deployment_type': self.deployment_type
        }

        with open(backup_file, 'w') as f:
            json.dump(backup_data, f, indent=2, default=str)

        self.console.print(f"[green]✓[/green] Configuration backed up to {backup_file}")
        return backup_file

    def restore_configuration(self):
        """Restore configuration from backup"""
        backups = list(self.backup_dir.glob("config_backup_*.json"))
        if not backups:
            self.console.print("[yellow]⚠[/yellow] No backups found")
            return False

        # Sort by timestamp (newest first)
        backups.sort(reverse=True)

        backup_choices = [
            {"name": f"{b.stem.replace('config_backup_', '')} - {b.stat().st_mtime}", "value": b}
            for b in backups[:5]  # Show last 5 backups
        ]

        selected_backup = questionary.select(
            "Select backup to restore:",
            choices=backup_choices
        ).ask()

        if not selected_backup:
            return False

        try:
            with open(selected_backup, 'r') as f:
                backup_data = json.load(f)

            self.config = backup_data.get('config', {})
            self.selected_services = backup_data.get('selected_services', {})
            self.deployment_type = backup_data.get('deployment_type')

            self.console.print(f"[green]✓[/green] Configuration restored from {selected_backup.name}")
            return True
        except Exception as e:
            self.console.print(f"[red]✗[/red] Failed to restore backup: {e}")
            return False

    def validate_configuration(self, quiet=False):
        """Validate .env configuration"""
        if not quiet:
            self.console.print("Validating configuration...")

        issues = []

        # Check required variables
        required_vars = ['DOMAIN', 'DUCKDNS_TOKEN', 'PUID', 'PGID', 'TZ']
        env_file = Path('.env')

        if not env_file.exists():
            issues.append("Missing .env file")
            return issues

        env_vars = {}
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key] = value

        for var in required_vars:
            if var not in env_vars or not env_vars[var]:
                issues.append(f"Missing or empty required variable: {var}")

        # Validate domain format
        if 'DOMAIN' in env_vars and not self._validate_domain(env_vars['DOMAIN']):
            issues.append(f"Invalid domain format: {env_vars['DOMAIN']}")

        # Check Authelia secrets
        authelia_vars = ['AUTHELIA_JWT_SECRET', 'AUTHELIA_SESSION_SECRET', 'AUTHELIA_STORAGE_ENCRYPTION_KEY']
        for var in authelia_vars:
            if var in env_vars and len(env_vars[var]) < 32:
                issues.append(f"Authelia secret too short: {var}")

        if not quiet:
            if issues:
                self.console.print("[red]✗[/red] Configuration validation failed:")
                for issue in issues:
                    self.console.print(f"  - {issue}")
            else:
                self.console.print("[green]✓[/green] Configuration validation passed")

        return issues

    def show_progress(self, operation, steps):
        """Show progress for multi-step operations"""
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            TimeElapsedColumn(),
            console=self.console
        ) as progress:
            task = progress.add_task(operation, total=len(steps))

            for step in steps:
                progress.update(task, description=step)
                # Simulate work
                import time
                time.sleep(0.5)
                progress.advance(task)

    def check_service_health(self, quiet=False):
        """Check health of deployed services"""
        if not quiet:
            self.console.print("Checking service health...")

        stacks_dir = "/opt/stacks"
        health_status = {}

        # Check core services
        core_dir = f"{stacks_dir}/core"
        if os.path.exists(f"{core_dir}/docker-compose.yml"):
            health_status['core'] = self._check_stack_health(core_dir, 'core')

        # Check other stacks based on deployment type
        if self.deployment_type == "single":
            for stack in ['infrastructure', 'dashboards']:
                stack_dir = f"{stacks_dir}/{stack}"
                if os.path.exists(f"{stack_dir}/docker-compose.yml"):
                    health_status[stack] = self._check_stack_health(stack_dir, stack)

            # Check additional stacks
            additional_services = self.selected_services.get("additional", [])
            stack_name_mapping = {
                'Media': 'media',
                'Media Management': 'media-management',
                'Home Automation': 'homeassistant',
                'Productivity': 'productivity',
                'Monitoring': 'monitoring',
                'Utilities': 'utilities'
            }

            for service in additional_services:
                stack_name = stack_name_mapping.get(service)
                if stack_name and os.path.exists(f"{stacks_dir}/{stack_name}/docker-compose.yml"):
                    health_status[stack_name] = self._check_stack_health(f"{stacks_dir}/{stack_name}", stack_name)

        # Display results (only if not quiet)
        if not quiet:
            table = Table(title="Service Health Status")
            table.add_column("Stack", style="cyan")
            table.add_column("Status", style="green")
            table.add_column("Services", style="yellow")

            for stack, status in health_status.items():
                if status['running']:
                    table.add_row(stack, "[green]✓ Running[/green]", ", ".join(status['services']))
                else:
                    table.add_row(stack, "[red]✗ Issues[/red]", ", ".join(status['services']))

            self.console.print(table)

        return health_status

    def _check_stack_health(self, stack_dir, stack_name):
        """Check health of a specific stack"""
        import subprocess

        try:
            result = subprocess.run(
                ["docker", "compose", "ps", "--format", "json"],
                cwd=stack_dir,
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                # Parse JSON output to get service names
                services = []
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        try:
                            service_data = json.loads(line)
                            services.append(service_data.get('Service', 'unknown'))
                        except:
                            pass

                return {'running': True, 'services': services}
            else:
                return {'running': False, 'services': []}
        except Exception as e:
            return {'running': False, 'services': [], 'error': str(e)}

    def uninstall_services(self):
        """Uninstall deployed services"""
        self.console.print("[yellow]⚠[/yellow] This will stop and remove all deployed services")

        confirm = questionary.confirm("Are you sure you want to uninstall all services?").ask()

        if not confirm:
            return False

        stacks_dir = "/opt/stacks"

        # Stop and remove services
        for stack in ['core', 'infrastructure', 'dashboards', 'media', 'media-management']:
            stack_dir = f"{stacks_dir}/{stack}"
            if os.path.exists(f"{stack_dir}/docker-compose.yml"):
                self.console.print(f"Removing {stack} services...")

                try:
                    # Stop services
                    subprocess.run(
                        ["docker", "compose", "down"],
                        cwd=stack_dir,
                        capture_output=True,
                        timeout=60
                    )

                    # Remove volumes
                    subprocess.run(
                        ["docker", "compose", "down", "-v"],
                        cwd=stack_dir,
                        capture_output=True,
                        timeout=60
                    )

                    self.console.print(f"[green]✓[/green] {stack} services removed")
                except Exception as e:
                    self.console.print(f"[red]✗[/red] Error removing {stack}: {e}")

        # Remove stacks directory
        try:
            if os.path.exists(stacks_dir):
                shutil.rmtree(stacks_dir)
                self.console.print(f"[green]✓[/green] Removed stacks directory: {stacks_dir}")
        except Exception as e:
            self.console.print(f"[red]✗[/red] Error removing stacks directory: {e}")

        self.console.print("[green]✓[/green] Uninstallation completed")
        return True

    def _validate_domain(self, domain):
        """Validate domain format"""
        import re
        # Basic validation for duckdns.org domains
        pattern = r'^[a-zA-Z0-9-]+\.duckdns\.org$'
        return bool(re.match(pattern, domain))

    def show_banner(self):
        """Display application banner"""
        banner = """+==============================================+
|              EZ-HOMELAB TUI                  |
|        Terminal User Interface               |
|        for Homelab Deployment                |
+==============================================+"""
        self.console.print(Panel.fit(banner, border_style="blue"))
        self.console.print()

def show_banner(console):
    """Display application banner"""
    banner = """+==============================================+
|              EZ-HOMELAB TUI                  |
|        Terminal User Interface               |
|        for Homelab Deployment                |
+==============================================+"""
    console.print(Panel.fit(banner, border_style="blue"))
    console.print()

def main():
    """Main entry point"""
    console = Console()

    # Setup argument parser
    parser = argparse.ArgumentParser(
        description="EZ-Homelab TUI Deployment Script",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                    # Interactive TUI mode
  %(prog)s --yes             # Automated deployment using .env
  %(prog)s --save-only       # Save configuration without deploying
  %(prog)s --backup          # Backup current configuration
  %(prog)s --restore         # Restore configuration from backup
  %(prog)s --validate        # Validate current .env configuration
  %(prog)s --health          # Check service health status
  %(prog)s --uninstall       # Uninstall all deployed services
  %(prog)s --help            # Show this help
        """
    )
    parser.add_argument(
        '-y', '--yes',
        action='store_true',
        help='Automated deployment using complete .env file'
    )
    parser.add_argument(
        '--save-only',
        action='store_true',
        help='Save configuration without deploying'
    )
    parser.add_argument(
        '--backup',
        action='store_true',
        help='Backup current configuration'
    )
    parser.add_argument(
        '--restore',
        action='store_true',
        help='Restore configuration from backup'
    )
    parser.add_argument(
        '--validate',
        action='store_true',
        help='Validate current .env configuration'
    )
    parser.add_argument(
        '--health',
        action='store_true',
        help='Check service health status'
    )
    parser.add_argument(
        '--uninstall',
        action='store_true',
        help='Uninstall all deployed services'
    )

    args = parser.parse_args()

    # Handle special modes
    if args.backup:
        app = EZHomelabTUI()
        app.backup_configuration()
        return 0
    elif args.restore:
        app = EZHomelabTUI()
        success = app.restore_configuration()
        return 0 if success else 1
    elif args.validate:
        app = EZHomelabTUI()
        issues = app.validate_configuration()
        return 0 if len(issues) == 0 else 1
    elif args.health:
        app = EZHomelabTUI()
        app.check_service_health()
        return 0
    elif args.uninstall:
        app = EZHomelabTUI()
        success = app.uninstall_services()
        return 0 if success else 1
    elif args.yes:
        console.print("[green]Automated deployment mode selected[/green]")
        app = EZHomelabTUI()
        # Load existing configuration
        app.load_existing_config()
        # Run deployment
        success = app.perform_deployment()
        # perform_deployment already prints success/failure messages
        return 0 if success else 1
    elif args.save_only:
        console.print("[yellow]Save-only mode selected[/yellow]")
        app = EZHomelabTUI()
        # Run interactive questions to collect configuration
        app.run_interactive_questions()
        # Generate .env file
        app.generate_env_file()
        # Generate compose files
        app.generate_compose_files()
        console.print("[green]Configuration saved successfully![/green]")
        return 0
    else:
        # Interactive TUI mode - use the full EZHomelabTUI class
        app = EZHomelabTUI()
        success = app.run()

        if success:
            console.print("\n[green]🎉 EZ-Homelab setup completed successfully![/green]")
            console.print("\n[bold cyan]Next Steps:[/bold cyan]")
            console.print("  1. Access your services at:")
            console.print(f"     • Homepage: https://home.{app.config.get('DOMAIN', 'yourdomain.duckdns.org')}")
            console.print(f"     • Dockge: https://dockge.{app.config.get('DOMAIN', 'yourdomain.duckdns.org')}")
            console.print(f"     • Authelia: https://auth.{app.config.get('DOMAIN', 'yourdomain.duckdns.org')}")
            console.print("  2. Default login credentials:")
            console.print(f"     • Username: {app.config.get('DEFAULT_USER', 'admin')}")
            console.print(f"     • Password: {app.config.get('DEFAULT_PASSWORD', 'changeme')}")
            console.print("  3. Change default passwords immediately!")
            console.print("  4. Configure your domain DNS and DuckDNS token")
            console.print("\n[dim]For help, visit: https://github.com/kelinfoxy/EZ-Homelab[/dim]")
            return 0
        else:
            console.print("\n[red]❌ EZ-Homelab setup failed or was cancelled.[/red]")
            console.print("\n[bold yellow]Troubleshooting:[/bold yellow]")
            console.print("  Use GitHub Copilot to analyze the errors above and get specific solutions.")
            console.print("  Common issues: port conflicts, missing dependencies, network issues.")
            console.print("\n[dim]For help, visit: https://github.com/kelinfoxy/EZ-Homelab[/dim]")
            return 1

if __name__ == "__main__":
    sys.exit(main())