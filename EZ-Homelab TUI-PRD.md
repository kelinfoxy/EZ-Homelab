# EZ-Homelab TUI Deployment Script - Product Requirements Document

## Executive Summary

The EZ-Homelab TUI Deployment Script is a modern, user-friendly replacement for the existing complex bash deployment script. It provides an interactive terminal user interface (TUI) for deploying and managing a comprehensive homelab infrastructure using Docker Compose stacks, with support for automated deployment via configuration files.

## Objectives

### Primary Objectives
- Replace the complex 1000+ line bash script with a maintainable Python TUI application
- Provide three distinct deployment scenarios: Single Server Full, Core Server, and Remote Server
- Enable both interactive and fully automated deployment workflows
- Handle complete system setup including Docker and NVIDIA GPU configuration
- Ensure maximum user convenience by minimizing required logouts/reboots

### Secondary Objectives
- Improve user experience with modern TUI design using Rich + Questionary
- Provide flexible service selection and configuration options
- Support save-only mode for configuration preparation
- Include comprehensive validation and error handling
- Maintain backward compatibility with existing .env configurations

## Target Users

### Primary Users
- **Homelab Enthusiasts**: Users setting up personal server infrastructure
- **Self-Hosters**: Individuals deploying media servers, productivity tools, and monitoring
- **System Administrators**: Those managing small-scale server deployments

### User Personas
1. **Alex the Homelab Beginner**: New to self-hosting, needs guided setup with sensible defaults
2. **Jordan the Power User**: Experienced user who wants fine-grained control over service selection
3. **Sam the DevOps Engineer**: Needs automated deployment for multiple servers, prefers configuration files

### Technical Requirements
- Ubuntu/Debian Linux systems (primary target)
- Basic command-line familiarity
- Internet access for package downloads
- Administrative privileges (sudo access)

## Functional Requirements

### Core Features

#### 1. Deployment Scenarios
**FR-DEP-001**: Support three deployment scenarios
- Single Server Full: Deploy all core, infrastructure, and dashboard services
- Core Server: Deploy only core infrastructure and dashboards
- Remote Server: Deploy infrastructure and dashboards without core services

**FR-DEP-002**: Automated scenario selection based on user choice
- Pre-select appropriate services for each scenario
- Allow user customization within scenario constraints

#### 2. Configuration Management
**FR-CONF-001**: Load existing .env configuration
- Parse existing .env file on startup
- Validate configuration completeness
- Pre-populate TUI defaults with existing values

**FR-CONF-002**: Support deployment configuration section in .env
- Parse [DEPLOYMENT] section with service selections
- Enable fully automated deployment with --yes flag
- Validate deployment configuration completeness

**FR-CONF-003**: Interactive configuration collection
- Skip questions for valid existing values
- Provide sensible defaults for all settings
- Validate user input in real-time

#### 3. System Setup & Prerequisites
**FR-SYS-001**: Pre-flight system checks
- OS compatibility (Ubuntu/Debian)
- Available disk space (>10GB)
- Internet connectivity
- System architecture validation

**FR-SYS-002**: Docker installation and configuration
- Detect existing Docker installation
- Install Docker if missing
- Add user to docker group
- Avoid requiring logout through smart command execution

**FR-SYS-003**: NVIDIA GPU support
- Detect NVIDIA GPU presence
- Install official NVIDIA drivers using official installers
- Install NVIDIA Container Toolkit
- Handle reboot requirements intelligently

**FR-SYS-004**: Dependency management
- Install required system packages
- Install Python dependencies (Rich, Questionary, python-dotenv)
- Update system packages as needed

#### 4. Service Selection & Customization
**FR-SVC-001**: Core services selection
- Display scenario-appropriate core services
- Allow include/exclude for flexibility
- Enforce minimum requirements for each scenario

**FR-SVC-002**: Infrastructure services selection
- Provide checkbox interface for all infrastructure services
- Include descriptions and default selections
- Allow complete customization

**FR-SVC-003**: Additional stacks preparation
- Multi-select interface for optional service stacks
- Copy selected stacks to /opt/stacks/ without starting
- Enable later deployment via Dockge

#### 5. User Interface & Experience
**FR-UI-001**: Interactive TUI design
- Use Rich + Questionary for modern terminal interface
- Provide clear, descriptive prompts
- Include help text and validation messages

**FR-UI-002**: Conditional question flow
- Show questions only when relevant
- Skip questions with valid existing values
- Provide logical question progression

**FR-UI-003**: Configuration summary and confirmation
- Display formatted summary of all settings
- Allow review before proceeding
- Provide options to save, change, or exit

#### 6. Deployment Execution
**FR-DEP-003**: One-step deployment process
- Handle all installation and deployment in single script run
- Minimize required logouts/reboots
- Provide clear progress indication

**FR-DEP-004**: Smart reboot handling
- Detect what requires reboot vs logout vs nothing
- Perform reboot-requiring actions last
- Support both automatic and manual reboot options

**FR-DEP-005**: Error handling and recovery
- Provide clear error messages
- Allow recovery from partial failures
- Maintain configuration state across retries

### Command Line Interface

#### Launch Options
**FR-CLI-001**: Support multiple launch modes
- Interactive mode (default): Full TUI experience
- Automated mode (--yes): Use complete .env configuration
- Save-only mode (--save-only): Collect configuration without deploying
- Help mode (--help): Display usage information

#### Configuration Output
**FR-CLI-002**: Flexible configuration saving
- Save to .env by default
- Allow custom filename specification
- Preserve existing .env structure and comments

## Non-Functional Requirements

### Performance
**NFR-PERF-001**: Fast startup and validation
- Complete pre-flight checks within 30 seconds
- Validate .env file parsing within 5 seconds
- Provide responsive TUI interaction

**NFR-PERF-002**: Efficient deployment
- Complete full deployment within 15-30 minutes
- Provide real-time progress indication
- Handle large downloads gracefully

### Reliability
**NFR-REL-001**: Robust error handling
- Graceful handling of network failures
- Clear error messages with recovery suggestions
- Maintain system stability during installation

**NFR-REL-002**: Configuration validation
- Validate all user inputs before proceeding
- Check for conflicting configurations
- Prevent deployment with invalid settings

### Usability
**NFR-USAB-001**: Intuitive interface design
- Clear, descriptive prompts and help text
- Logical question flow and grouping
- Consistent terminology and formatting

**NFR-USAB-002**: Accessibility considerations
- Support keyboard navigation
- Provide clear visual feedback
- Include progress indicators for long operations

### Security
**NFR-SEC-001**: Secure credential handling
- Mask password inputs in TUI
- Store credentials securely in .env
- Validate certificate and token formats

**NFR-SEC-002**: Safe system modifications
- Require explicit user confirmation for system changes
- Provide clear warnings for potentially disruptive actions
- Maintain secure file permissions

### Compatibility
**NFR-COMP-001**: OS compatibility
- Primary support for Ubuntu 20.04+ and Debian 11+
- Graceful handling of different package managers
- Architecture support for amd64 and arm64

**NFR-COMP-002**: Backward compatibility
- Read existing .env files without modification
- Support legacy configuration formats
- Provide migration path for old configurations

## Technical Requirements

### Technology Stack
**TR-TECH-001**: Core technologies
- Python 3.8+ as runtime environment
- Rich library for terminal formatting
- Questionary library for interactive prompts
- python-dotenv for configuration parsing

**TR-TECH-002**: System integration
- Docker and Docker Compose for container management
- systemd for service management
- apt/dpkg for package management
- Official NVIDIA installation tools

### Architecture
**TR-ARCH-001**: Modular design
- Separate concerns for UI, validation, and deployment
- Configurable question flow engine
- Pluggable deployment modules

**TR-ARCH-002**: State management
- Maintain configuration state throughout TUI flow
- Support save/restore of partial configurations
- Handle interruption and resumption gracefully

### Dependencies
**TR-DEPS-001**: Python packages
- rich>=12.0.0
- questionary>=1.10.0
- python-dotenv>=0.19.0
- pyyaml>=6.0 (for configuration parsing)

**TR-DEPS-002**: System packages
- curl, wget, git (for downloads and version control)
- htop, nano, vim (system monitoring and editing)
- ufw, fail2ban (security)
- unattended-upgrades, apt-listchanges (system maintenance)
- sshpass (for multi-server setup)

## User Experience Requirements

### Onboarding Flow
**UX-ONB-001**: First-time user experience
- Clear welcome message and overview
- Guided setup with sensible defaults
- Help text for each question

**UX-ONB-002**: Returning user experience
- Load existing configuration automatically
- Skip redundant questions
- Provide quick confirmation for known setups

### Interaction Patterns
**UX-INT-001**: Question flow optimization
- Group related questions together
- Provide progress indication
- Allow backtracking and editing

**UX-INT-002**: Feedback and validation
- Real-time input validation
- Clear error messages with suggestions
- Success confirmations for completed steps

### Error Recovery
**UX-ERR-001**: Graceful error handling
- Clear error descriptions
- Suggested recovery actions
- Option to retry or modify configuration

**UX-ERR-002**: Partial failure recovery
- Save progress on interruption
- Allow resumption from last completed step
- Provide rollback options where possible

## Success Criteria

### Functional Completeness
- [ ] All three deployment scenarios work correctly
- [ ] Automated deployment with --yes flag functions
- [ ] Save-only mode preserves configuration
- [ ] Docker and NVIDIA installation work reliably
- [ ] Service selection and customization work as specified

### User Experience
- [ ] TUI is intuitive and responsive
- [ ] Configuration validation prevents errors
- [ ] Error messages are helpful and actionable
- [ ] Deployment completes without requiring logout/reboot (except when absolutely necessary)

### Technical Quality
- [ ] Code is well-structured and maintainable
- [ ] Comprehensive error handling implemented
- [ ] Configuration parsing is robust
- [ ] System integration works reliably across Ubuntu/Debian versions

### Performance Targets
- [ ] Pre-flight checks complete within 30 seconds
- [ ] TUI startup within 5 seconds
- [ ] Full deployment completes within 30 minutes
- [ ] Memory usage remains under 200MB during execution

## Implementation Plan

### Phase 1: Core Infrastructure (Week 1-2)
- Set up Python project structure
- Implement basic TUI framework with Rich + Questionary
- Create configuration parsing and validation
- Implement pre-flight system checks

### Phase 2: System Setup (Week 3-4)
- Implement Docker installation and configuration
- Add NVIDIA GPU detection and official driver installation
- Create dependency management system
- Implement smart reboot/logout handling

### Phase 3: Configuration Management (Week 5-6)
- Build dynamic question flow engine
- Implement .env parsing and [DEPLOYMENT] section support
- Create configuration validation system
- Add save-only functionality

### Phase 4: Deployment Logic (Week 7-8)
- Implement deployment scenario logic
- Create service selection and preparation system
- Build deployment execution engine
- Add progress indication and error handling

### Phase 5: Testing & Polish (Week 9-10)
- Comprehensive testing across Ubuntu/Debian versions
- User experience testing and refinement
- Documentation and help system
- Performance optimization

## Dependencies & Constraints

### External Dependencies
- **NVIDIA Official Installers**: Must use official NVIDIA installation methods
- **Docker Official Installation**: Use official Docker installation scripts
- **Ubuntu/Debian Package Repositories**: Rely on standard package sources

### Technical Constraints
- **Python Version**: Minimum Python 3.8 required for modern type hints
- **Terminal Compatibility**: Must work in standard Linux terminals
- **Network Requirements**: Internet access required for downloads
- **Privilege Requirements**: sudo access required for system modifications

### Business Constraints
- **Open Source**: Must remain free and open source
- **Backward Compatibility**: Should not break existing .env files
- **Documentation**: Comprehensive documentation required
- **Community Support**: Should be maintainable by community contributors

## Risk Assessment

### High Risk Items
- **NVIDIA Installation**: Complex driver installation across different GPU models
- **Reboot Handling**: Ensuring one-step installation without logout requirements
- **Configuration Validation**: Complex validation logic for interdependent settings

### Mitigation Strategies
- **Testing**: Extensive testing on multiple hardware configurations
- **Fallback Options**: Provide manual installation instructions as backup
- **Modular Design**: Allow components to be disabled/enabled independently
- **User Communication**: Clear warnings and alternative options for complex scenarios

## Future Enhancements

### Planned Features
- Support for additional Linux distributions
- Web-based configuration interface
- Integration with configuration management tools
- Advanced deployment templates and presets

### Maintenance Considerations
- Regular updates for new NVIDIA driver versions
- Compatibility testing with new Ubuntu/Debian releases
- Community contribution guidelines and testing frameworks

---

*This PRD serves as the authoritative specification for the EZ-Homelab TUI Deployment Script. All development decisions should reference this document to ensure alignment with user requirements and technical constraints.*</content>
<parameter name="filePath">c:\Users\kelin\Documents\Apps\GitHub\EZ-Homelab\EZ-Homelab TUI-PRD.md