# EZ-Homelab Enhanced Setup Scripts - Product Requirements Document

## Document Information
- **Project**: EZ-Homelab Enhanced Setup Scripts
- **Version**: 1.0
- **Date**: January 29, 2026
- **Author**: EZ-Homelab Development Team
- **Location**: `scripts/enhanced-setup/`

## Executive Summary

The EZ-Homelab Enhanced Setup Scripts project aims to replace the complex Python TUI deployment system with a modular, bash-based suite of scripts that provide automated, user-friendly deployment of the EZ-Homelab infrastructure. This approach prioritizes simplicity, minimal manual intervention, and cross-architecture compatibility (AMD64/ARM64) while maintaining the project's file-based, AI-manageable architecture.

The solution consists of 11 specialized scripts that handle different aspects of homelab deployment, from pre-flight checks to ongoing management and monitoring.

## Objectives

### Primary Objectives
- **Simplify Deployment**: Reduce manual steps for inexperienced users to near-zero
- **Cross-Platform Support**: Ensure seamless operation on AMD64 and ARM64 architectures
- **Modular Design**: Create reusable, focused scripts instead of monolithic solutions
- **Error Resilience**: Provide clear error messages and recovery options
- **Maintainability**: Keep code AI-manageable and file-based

### Secondary Objectives
- **User Experience**: Implement text-based UI with dynamic menus using dialog/whiptail
- **Automation**: Support both interactive and non-interactive (scripted) execution
- **Monitoring**: Provide status reporting tools for ongoing management
- **Security**: Maintain security-first principles with proper permission handling

## Target Users

### Primary Users
- **Inexperienced Homelab Enthusiasts**: Users new to Docker/homelab concepts
- **Raspberry Pi Users**: ARM64 users with resource constraints
- **Single-Server Deployers**: Users setting up complete homelabs on one machine

### Secondary Users
- **Advanced Users**: Those who want granular control over deployment
- **Multi-Server Administrators**: Users managing distributed homelab setups
- **Developers**: Contributors to EZ-Homelab who need to test changes

## Requirements

### Functional Requirements

#### FR-1: Pre-Flight System Validation (`preflight.sh`)
- **Description**: Perform comprehensive system checks before deployment
- **Requirements**:
  - Check OS compatibility (Debian/Ubuntu-based systems)
  - Verify architecture support (AMD64/ARM64)
  - Assess available disk space (minimum 20GB for core deployment)
  - Check network connectivity and DNS resolution
  - Validate CPU and memory resources
  - Detect existing Docker installation
  - Check for NVIDIA GPU presence
- **Output**: Detailed report with pass/fail status and recommendations
- **UI**: Progress bar with whiptail/dialog

#### FR-2: System Setup and Prerequisites (`setup.sh`)
- **Description**: Install and configure Docker and system prerequisites
- **Requirements**:
  - Install Docker Engine (version 24.0+)
  - Configure Docker daemon for Traefik
  - Add user to docker group
  - Install required system packages (curl, jq, git)
  - Set up virtual environments for Python dependencies (ARM64 compatibility)
  - Handle system reboot requirements gracefully
- **Output**: Installation log with success confirmation
- **UI**: Progress indicators and user prompts for reboots

#### FR-3: NVIDIA GPU Setup (`nvidia.sh`)
- **Description**: Install NVIDIA drivers and configure GPU support
- **Requirements**:
  - Detect NVIDIA GPU presence
  - Install official NVIDIA drivers (version 525+ for current GPUs)
  - Configure Docker NVIDIA runtime
  - Validate GPU functionality with nvidia-smi
  - Handle driver conflicts and updates
- **Output**: GPU detection and installation status
- **UI**: Confirmation prompts and progress tracking

#### FR-4: Pre-Deployment Configuration Wizard (`pre-deployment-wizard.sh`)
- **Description**: Interactive setup of deployment options and environment
- **Requirements**:
  - Create required Docker networks (traefik-network, homelab-network)
  - Guide user through deployment type selection (Core, Single Server, Remote)
  - Service selection with checkboxes (dynamic based on deployment type)
  - Environment variable collection (.env file creation)
  - Domain configuration (DuckDNS setup)
  - Architecture-specific option handling
- **Output**: Generated .env file and network configurations
- **UI**: Dynamic dialog menus with conditional questions

#### FR-5: Multi-Purpose Validation (`validate.sh`)
- **Description**: Validate configurations, compose files, and deployment readiness
- **Requirements**:
  - Validate .env file completeness and syntax
  - Check Docker Compose file syntax (`docker compose config`)
  - Verify network availability
  - Validate service dependencies
  - Check SSL certificate readiness
  - Perform architecture-specific validations
- **Output**: Validation report with error details and fixes
- **UI**: Optional progress display, detailed error messages

#### FR-6: Configuration Localization (`localize.sh`)
- **Description**: Replace template variables in service configurations
- **Requirements**:
  - Process per-service configuration files
  - Replace ${VARIABLE} placeholders with environment values
  - Handle nested configurations (YAML, JSON, conf files)
  - Support selective localization (single service or all)
  - Preserve original templates for generalization
- **Output**: Localized configuration files ready for deployment
- **UI**: Progress for batch operations

#### FR-7: Configuration Generalization (`generalize.sh`)
- **Description**: Reverse localization for template maintenance
- **Requirements**:
  - Extract environment values back to ${VARIABLE} format
  - Update template files from localized versions
  - Support selective generalization
  - Maintain configuration integrity
- **Output**: Updated template files
- **UI**: Confirmation prompts for destructive operations

#### FR-8: Service Deployment (`deploy.sh`)
- **Description**: Deploy single stacks or complete homelab
- **Requirements**:
  - Support deployment of individual services/stacks
  - Enforce deployment order (core first, then others)
  - Handle service dependencies and health checks
  - Provide rollback options for failed deployments
  - Support both interactive and automated modes
  - Log deployment progress and errors
- **Output**: Deployment status and access URLs
- **UI**: Progress bars and real-time status updates

#### FR-9: Uninstall and Cleanup (`uninstall.sh`)
- **Description**: Remove services, stacks, or complete homelab
- **Requirements**:
  - Support selective uninstall (service, stack, or full)
  - Preserve user data with confirmation
  - Clean up Docker networks and volumes
  - Remove generated configurations
  - Provide safety confirmations
- **Output**: Cleanup report with remaining resources
- **UI**: Confirmation dialogs and progress tracking

#### FR-10: Proxy Configuration Status (`proxy-status.sh`)
- **Description**: Generate comprehensive proxy configuration report
- **Requirements**:
  - Analyze Docker Compose labels for Traefik routing
  - Check external host configurations in Traefik dynamic files
  - Validate Sablier lazy loading configurations
  - Support local and remote server analysis
  - Include all stacks (deployed and not deployed)
  - Generate table-format reports
- **Output**: HTML/PDF report with configuration status
- **UI**: Table display with color-coded status

#### FR-11: DNS and SSL Status (`dns-status.sh`)
- **Description**: Report on DuckDNS and Let's Encrypt certificate status
- **Requirements**:
  - Check DuckDNS subdomain resolution
  - Validate SSL certificate validity and expiration
  - Monitor certificate renewal status
  - Report on DNS propagation
  - Include wildcard certificate coverage
- **Output**: Certificate and DNS health report
- **UI**: Status dashboard with alerts

### Non-Functional Requirements

#### NFR-1: Performance
- **Startup Time**: Scripts should complete pre-flight checks in <30 seconds
- **Deployment Time**: Core services deployment in <5 minutes on standard hardware
- **Memory Usage**: <100MB RAM for script execution
- **Disk Usage**: <500MB for script and temporary files

#### NFR-2: Reliability
- **Error Recovery**: Scripts should handle common failures gracefully
- **Idempotency**: Safe to re-run scripts without side effects
- **Logging**: Comprehensive logging to `/var/log/ez-homelab/`
- **Backup**: Automatic backup of configurations before modifications

#### NFR-3: Usability
- **User Guidance**: Clear error messages with suggested fixes
- **Documentation**: Inline help (`--help`) for all scripts
- **Localization**: English language with clear technical terms
- **Accessibility**: Keyboard-only navigation for text UI

#### NFR-4: Security
- **Permission Handling**: Proper sudo usage with minimal privilege escalation
- **Secret Management**: Secure handling of passwords and API keys
- **Network Security**: No unnecessary port exposures during setup
- **Audit Trail**: Log all configuration changes

#### NFR-5: Compatibility
- **OS Support**: Debian 11+, Ubuntu 20.04+, Raspberry Pi OS
- **Architecture**: AMD64 and ARM64
- **Docker**: Version 20.10+ with Compose V2
- **Dependencies**: Use only widely available packages

## Technical Specifications

### Software Dependencies
- **Core System**:
  - bash 5.0+
  - curl 7.68+
  - jq 1.6+
  - git 2.25+
  - dialog 1.3+ (or whiptail 0.52+)
- **Docker Ecosystem**:
  - Docker Engine 24.0+
  - Docker Compose V2 (docker compose plugin)
  - Docker Buildx for multi-architecture builds
- **NVIDIA (Optional)**:
  - NVIDIA Driver 525+
  - nvidia-docker2 2.12+
- **Python (Virtual Environment)**:
  - Python 3.9+
  - pip 21.0+
  - virtualenv 20.0+

### Architecture Considerations
- **AMD64**: Full feature support, optimized performance
- **ARM64**: PiWheels integration, resource-aware deployment
- **Multi-Server**: TLS certificate management for remote access

### File Structure
```
scripts/enhanced-setup/
├── prd.md                           # This document
├── preflight.sh                     # System validation
├── setup.sh                         # Docker installation
├── nvidia.sh                        # GPU setup
├── pre-deployment-wizard.sh         # Configuration wizard
├── validate.sh                      # Multi-purpose validation
├── localize.sh                      # Template processing
├── generalize.sh                    # Template reversal
├── deploy.sh                        # Service deployment
├── uninstall.sh                     # Cleanup operations
├── proxy-status.sh                  # Proxy configuration report
├── dns-status.sh                    # DNS/SSL status report
├── lib/                             # Shared functions
│   ├── common.sh                    # Utility functions
│   ├── ui.sh                        # Dialog/whiptail helpers
│   └── validation.sh                # Validation logic
├── templates/                       # Configuration templates
└── logs/                            # Execution logs
```

### Integration Points
- **EZ-Homelab Repository**: Located in `~/EZ-Homelab/`
- **Runtime Location**: Deploys to `/opt/stacks/`
- **Configuration Source**: Uses `.env` files and templates
- **Service Definitions**: Leverages existing `docker-compose/` directory

## User Stories

### US-1: First-Time Raspberry Pi Setup
**As a** Raspberry Pi user new to homelabs  
**I want** a guided setup process  
**So that** I can deploy EZ-Homelab without Docker knowledge  

**Acceptance Criteria**:
- Pre-flight detects ARM64 and guides Pi-specific setup
- Setup script handles Docker installation on Raspbian
- Wizard provides Pi-optimized service selections
- Deployment completes without manual intervention

### US-2: Multi-Server Homelab Administrator
**As a** homelab administrator with multiple servers  
**I want** to deploy services across servers  
**So that** I can manage distributed infrastructure  

**Acceptance Criteria**:
- Proxy-status reports configuration across all servers
- Deploy script supports remote server targeting
- DNS-status validates certificates for all subdomains
- Uninstall handles cross-server cleanup

### US-3: Development and Testing
**As a** developer contributing to EZ-Homelab  
**I want** to validate changes before deployment  
**So that** I can ensure quality and compatibility  

**Acceptance Criteria**:
- Validate script checks all configurations
- Localize/generalize supports template development
- Deploy script allows single-service testing
- Status scripts provide detailed diagnostic information

## Implementation Plan

### Phase 1: Core Infrastructure (Week 1-2)
- Implement preflight.sh and setup.sh
- Create shared library functions
- Set up basic dialog UI framework

### Phase 2: Configuration Management (Week 3-4)
- Build pre-deployment-wizard.sh
- Implement localize.sh and generalize.sh
- Add validation.sh framework

### Phase 3: Deployment Engine (Week 5-6)
- Create deploy.sh with service orchestration
- Implement uninstall.sh
- Add comprehensive error handling

### Phase 4: Monitoring and Reporting (Week 7-8)
- Build proxy-status.sh and dns-status.sh
- Add nvidia.sh for GPU support
- Comprehensive testing across architectures

### Phase 5: Polish and Documentation (Week 9-10)
- UI/UX improvements
- Documentation and help systems
- Performance optimization

## Risk Assessment

### Technical Risks
- **ARM64 Compatibility**: Mitigated by early testing on Raspberry Pi
- **Dialog/Whiptail Availability**: Low risk - included in Debian/Ubuntu
- **Docker API Changes**: Mitigated by using stable Docker versions

### Operational Risks
- **User Adoption**: Addressed through clear documentation and UI
- **Maintenance Overhead**: Mitigated by modular design
- **Security Vulnerabilities**: Addressed through regular updates and audits

## Success Metrics

### Quantitative Metrics
- **Deployment Success Rate**: >95% first-time success
- **Setup Time**: <15 minutes for basic deployment
- **Error Rate**: <5% user-reported issues
- **Architecture Coverage**: Full AMD64/ARM64 support

### Qualitative Metrics
- **User Satisfaction**: Positive feedback on simplicity
- **Community Adoption**: Increased GitHub stars and contributors
- **Maintainability**: Easy to add new services and features

## Conclusion

The EZ-Homelab Enhanced Setup Scripts project will provide a robust, user-friendly deployment system that addresses the limitations of the previous Python approach while maintaining the project's core principles of simplicity and automation. The modular script design ensures maintainability and extensibility for future homelab needs.

This PRD serves as the foundation for implementation and will be updated as development progresses.