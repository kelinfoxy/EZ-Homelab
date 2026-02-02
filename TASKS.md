# EZ-Homelab Script Refactoring Tasks

## Overview
This document outlines the updated plan for refactoring `ez-homelab.sh` based on user requirements. Tasks are prioritized by impact and dependencies. All files are in the same repo. Dry-run output should be user-friendly.

## Task Categories

### 1. Menu and Workflow Updates (High Priority)
- **1.1: Create `install-prerequisites.sh`**  
  Extract `system_setup()` into a standalone script that must run as root/sudo. Update Option 1 to launch it with sudo if needed.  
  *Effort*: 2-3 hours. *Files*: New `install-prerequisites.sh`, modify `ez-homelab.sh`.

- **1.2: Update Menu Option 3 Prompts**  
  For Option 3, check if default values are valid. If yes, prompt to use defaults or not. If not, prompt for all REQUIRED_VARS to ensure easy deployment. Reword prompts to clarify REMOTE_SERVER_* vars are for core server cert copying.  
  *Effort*: 1-2 hours. *Files*: `ez-homelab.sh` (`validate_and_prompt_variables()`, `prompt_for_variable()`).

- **1.3: Implement Menu Option 4 (NVIDIA Installation)**  
  Use `nvidia-detect` to determine GPU and official installer. Install NVIDIA drivers and Container Toolkit. Handle no-GPU gracefully.  
  *Effort*: 3-4 hours. *Files*: `ez-homelab.sh` or `install-prerequisites.sh`.

### 2. Bug Fixes (High Priority)
- **2.1: Remove Hardcoded Values**  
  Replace "kelin", "kelinreij", etc., with variables like `${DOMAIN}`, `${SERVER_IP}` in completion messages and examples.  
  *Effort*: 1 hour. *Files*: `ez-homelab.sh`.

- **2.2: Fix HOMEPAGE_ALLOWED_HOSTS**  
  Instead of hardcoding port (3003), extract the proper port from the Homepage compose file. Ensure line is `HOMEPAGE_ALLOWED_HOSTS="homepage.${DOMAIN},${SERVER_IP}:<extracted_port>"`.  
  *Effort*: 30 minutes. *Files*: `ez-homelab.sh` (`save_env_file()`).

### 3. New Features and Enhancements (Medium Priority)
- **3.1: Add Argument Parsing**  
  Implement CLI args (e.g., `--deploy-core`, `--dry-run`, `--verbose`) using `getopts` to bypass menu.  
  *Effort*: 2-3 hours. *Files*: `ez-homelab.sh` (`main()`).

- **3.2: Add Dry-Run Mode**  
  `--dry-run` simulates deployment: validate configs, show actions, log verbosely without executing. Output user-friendly summaries.  
  *Effort*: 2 hours. *Files*: `ez-homelab.sh` (`perform_deployment()`).

- **3.3: Enhance Console Logging for Verbose Mode**  
  Update `log_*` functions to output to console when `VERBOSE=true`.  
  *Effort*: 1 hour. *Files*: `ez-homelab.sh`.

- **3.4: Improve Error Handling**  
  Remove `set -e`; log errors but continue where possible. Use `||` for non-critical failures.  
  *Effort*: 2 hours. *Files*: `ez-homelab.sh`.

### 4. TLS and Multi-Server Logic Refinements (Medium Priority)
- **4.1: Clarify Variable Usage**  
  Ensure prompts distinguish: `SERVER_IP` for local machine, `REMOTE_SERVER_*` for core server. `${DOMAIN}` prompted even for additional servers (needed for configs).  
  *Effort*: 1-2 hours. *Files*: `ez-homelab.sh`.

### 5. Function Organization and Code Quality (Low Priority)
- **5.1: Audit and Improve Placeholder/Env Functions**  
  Rename `replace_env_placeholders()` to `localize_yml_file()` and `enhance_placeholder_replacement()` to `localize_deployment()`. Add error aggregation in bulk function. Make single-file function robust (permissions, backups only for existing targets, no repo modifications). Add post-replacement validation for Traefik labels. Handle special characters in values (passwords, hashes).  
  *Effort*: 2-3 hours. *Files*: `ez-homelab.sh`.

- **5.2: Modularize Code with More Functions**  
  Break `main()` into `parse_args()`, `handle_menu_choice()`, `prepare_deployment()`. Extract repeated logic (env copying, dir creation).  
  *Effort*: 3-4 hours. *Files*: `ez-homelab.sh`.

- **5.3: Fix Deployment Flow**  
  Streamline `perform_deployment()`: consistent step numbering, better recovery, dry-run integration.  
  *Effort*: 1 hour. *Files*: `ez-homelab.sh`.

## Implementation Order
1. Start with Bug Fixes (2.1-2.2) and Menu Option 1 (1.1).
2. Then New Features (3.1-3.4) and Menu Options (1.2-1.3).
3. Refinements (4.1, 5.1-5.3).

## Notes
- Test after each task: interactive menu, args, dry-run, multi-server.
- Dependencies: NVIDIA tasks require `nvidia-detect`; dry-run depends on args.
- Risks: Error handling changes may mask issues; validate thoroughly.