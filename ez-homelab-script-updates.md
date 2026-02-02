I've reviewed the full script and compared it against the show_main_menu() function and the overall logic flow. The script appears to be a comprehensive setup and deployment tool for the EZ-Homelab project, but there are several inconsistencies, bugs, and areas that need updating to align with the new menu options and intended behavior. Below is a detailed audit, focusing on the menu-related changes and broader issues.

1. Menu Structure and Logic Alignment
Current Menu Options (from show_main_menu()):
Install Prerequisites
Deploy Core Server
Deploy Additional Server
Install NVIDIA Drivers
The menu is clean and logical, with clear separation between system setup, core deployment, additional server setup, and optional NVIDIA support.
Code Handling:
Option 1: Sets FORCE_SYSTEM_SETUP=true, skips deployment, calls system_setup(), and exits. This is consistent.
Option 2: Sets DEPLOY_CORE=true, DEPLOY_INFRASTRUCTURE=true, DEPLOY_DASHBOARDS=true, SETUP_STACKS=true. Deploys everything for a core server. Consistent.
Option 3: Sets DEPLOY_CORE=false, DEPLOY_INFRASTRUCTURE=true, DEPLOY_DASHBOARDS=false, SETUP_STACKS=true. Deploys infrastructure and stacks (no core/dashboards) for additional servers. This makes sense for multi-server setups.
Option 4: Sets INSTALL_NVIDIA=true, skips deployment, logs a warning ("not yet implemented"), and exits. Placeholder only.
Issues:
The menu assumes Option 3 ("Deploy Additional Server") is for multi-server scenarios, but the script still prompts for all REQUIRED_VARS (e.g., DOMAIN, SERVER_IP) even for additional servers. For additional servers, some variables (like DOMAIN if it's core-specific) might not be needed, or SERVER_IP should be clarified as the additional server's IP. The code doesn't differentiate prompts based on deployment type, which could confuse users.
No command-line argument parsing (e.g., --debug, --verbose, or direct flags for deployment modes). The script logs args but doesn't use them, forcing interactive menu use.
The menu loop (while true) correctly handles invalid inputs and quits, but there's no way to bypass the menu (e.g., via env vars or args) for automated/scripted runs.
2. Bugs and Inconsistencies
Hardcoded Values in Completion Message:
Lines ~1520-1530: The success message hardcodes URLs like https://dockge.kelinreij.duckdns.org and https://homepage.kelinreij.duckdns.org. These should use ${DOMAIN} and ${SERVER_IP} for dynamic replacement. This is a critical bug as it won't work for other users/domains.
Double Setting of HOMEPAGE_ALLOWED_HOSTS:
In save_env_file() (lines ~630-633 and ~647-649): First sets HOMEPAGE_ALLOWED_HOSTS="${HOMEPAGE_SUBDOMAIN:-homepage}.${DOMAIN},${SERVER_IP}:3003", then overwrites it with HOMEPAGE_ALLOWED_HOSTS="homepage.${DOMAIN},${SERVER_IP}:3003". The second line ignores HOMEPAGE_SUBDOMAIN, causing inconsistency. Remove or merge the logic.
NVIDIA Driver Installation:
Option 4 is a placeholder with no implementation. The script should either implement basic NVIDIA setup (e.g., install drivers, CUDA) or remove the option to avoid user confusion.
Environment Variable Handling:
DEBUG and VERBOSE are set from env but not from command-line args. Add arg parsing (e.g., using getopts) to allow --debug, --verbose, etc.
In load_env_file_safely(), it exports vars but doesn't handle arrays or complex values well. No major issues, but could be improved for security (e.g., avoid logging secrets even in debug).
TLS and Multi-Server Logic:
For Option 3, setup_multi_server_tls() is called, which prompts for CORE_SERVER_IP if unset. This is good, but the script assumes SERVER_IP is the additional server's IP for TLS certs. Clarify in prompts or docs.
REQUIRED_VARS includes DOMAIN, but for additional servers, the domain might be inherited from core. The code doesn't skip prompts intelligently.
3. Code Structure and Messiness
Function Organization:
The script is long (1542 lines) and could be modularized (e.g., extract menu logic, validation, and deployment into separate functions or files). main() is bloated with inline logic.
Repeated patterns (e.g., copying .env files, replacing placeholders, chowning dirs) could be refactored into reusable functions.
Error Handling and Logging:
Good use of log_* functions, but debug_log only writes to file if DEBUG=true. Add console debug output for VERBOSE=true.
set -e is good, but some commands (e.g., docker network create) use || to ignore failures, which is inconsistent.
Deployment Flow:
After menu selection, the flow is: check system, prompt vars, save, validate, deploy. For Option 1/4, it exits early, which is fine. But for Options 2/3, it always runs enhance_placeholder_replacement() and validate_secrets(), even if not deploying core. validate_secrets() skips if DEPLOY_CORE=false, which is correct.
perform_deployment() has dynamic step numbering, but it's minor.
Security and Best Practices:
Uses sudo appropriately, but ACTUAL_USER logic is solid.
Secrets (e.g., passwords) are handled carefully, but AUTHELIA_ADMIN_PASSWORD generation could fail silently if Docker isn't available.
No input sanitization beyond basic validation in validate_variable().
4. Recommendations for Updates
Align with Menu Changes:
Update prompts in validate_and_prompt_variables() to skip irrelevant vars for Option 3 (e.g., don't prompt for DOMAIN if deploying additional server, or clarify it's for core).
Add command-line support: Parse args to set flags directly (e.g., .[ez-homelab.sh](http://_vscodecontentref_/1) --deploy-core --verbose to bypass menu).
Implement Option 4: Add NVIDIA driver installation logic in system_setup() or a new function (check GPU, install drivers, reboot if needed).
Fix Bugs:
Replace hardcoded URLs with variables (e.g., https://dockge.${DOMAIN}).
Fix HOMEPAGE_ALLOWED_HOSTS duplication.
Add validation to ensure DOMAIN and SERVER_IP are set before deployment.
General Cleanup:
Break main() into smaller functions (e.g., handle_menu_choice(), prepare_deployment()).
Add a --help option and better error messages.
Test multi-server flow thoroughly, as setup_multi_server_tls() has complex SSH logic.
Testing:
The script lacks automated tests. Add checks for each menu path (e.g., dry-run mode).
Validate YAML syntax in perform_deployment() before deploying.
Overall, the script is functional but messy, with the menu changes exposing inconsistencies in variable prompting and hardcoded values. The core logic aligns with the menu, but updates are needed for robustness, especially for multi-server setups. If you provide more details on what specific "menu changes" broke, I can refine this audit.






Overview of Requested Changes
Based on your notes, this is a comprehensive refactoring of ez-homelab.sh to improve usability, fix bugs, and enhance functionality. The changes focus on modularizing the script, improving user experience (e.g., better prompts, error handling), and adding new features like argument parsing and dry-run mode. Key themes include separating concerns (e.g., moving system setup to a new script), clarifying multi-server logic, and making the script more robust and user-friendly.

Scope and Impact:

Lines of Code: The script is ~1542 lines; changes will add/modify ~200-400 lines, potentially splitting into multiple files.
Breaking Changes: Menu Option 1 now requires a separate script; variable prompts and logic for Option 3/multi-server will change; hardcoded values will be removed.
Testing Needs: High—test all menu options, argument parsing, dry-run, error scenarios, and multi-server TLS. Validate on different systems (with/without NVIDIA, core vs. additional servers).
Dependencies: Requires nvidia-detect (for Option 4), access to NVIDIA repos, and ensuring the new install-prerequisites.sh works across distros.
Estimated Effort: 10-15 hours for implementation, plus testing. Prioritize bugs and core menu fixes first.
Risks: Error handling changes could mask real issues; multi-server logic is complex—ensure backward compatibility.
The tasks are broken down into categories below, with priorities (High/Medium/Low) based on impact and dependencies.

Task Breakdown
1. Menu and Workflow Updates (High Priority - Core User Experience)
Task 1.1: Create install-prerequisites.sh
Extract system_setup() and related logic into a new standalone script. Ensure it must run as root/sudo. Update Option 1 in ez-homelab.sh to detect if running as root; if not, use sudo to launch the new script. Handle cases where sudo isn't available (e.g., log error and exit).
Effort: 2-3 hours. Dependencies: None. Files: New install-prerequisites.sh, modify ez-homelab.sh.

Task 1.2: Update Menu Option 3 Prompts
Ensure Option 3 prompts for all REQUIRED_VARS (no skipping). Reword prompts to clarify that variables like DOMAIN and SERVER_IP are for the local (additional) server, while REMOTE_SERVER_* vars are for the core server (e.g., "Enter the IP of the core server where Traefik is running"). Keep existing variable names but improve descriptions.
Effort: 1-2 hours. Dependencies: Review .env.example for REMOTE_SERVER context. Files: Modify validate_and_prompt_variables() and prompt_for_variable() in ez-homelab.sh.

Task 1.3: Implement Menu Option 4 (NVIDIA Installation)
Use nvidia-detect to identify the GPU and determine the official NVIDIA installer. Install NVIDIA drivers and the NVIDIA Container Toolkit (for Docker GPU support). Handle errors gracefully (e.g., if no GPU detected, skip). Integrate into system_setup() or a new function.
Effort: 3-4 hours. Dependencies: Install nvidia-detect if needed; test on systems with/without NVIDIA GPUs. Files: Modify/add functions in ez-homelab.sh or install-prerequisites.sh.

2. Bug Fixes (High Priority - Prevents User Errors)
Task 2.1: Remove Hardcoded Values
Replace all instances of "kelin", "kelinreij", "kelin-casa", etc., with appropriate variables (e.g., ${DOMAIN}, ${SERVER_IP}). Update completion messages, URLs, and any examples.
Effort: 1 hour. Dependencies: Search the script for these strings. Files: ez-homelab.sh.

Task 2.2: Fix HOMEPAGE_ALLOWED_HOSTS
Remove HOMEPAGE_SUBDOMAIN references. Ensure the line is exactly HOMEPAGE_ALLOWED_HOSTS="homepage.${DOMAIN},${SERVER_IP}:3003" (no duplication or overwrites).
Effort: 30 minutes. Dependencies: Check save_env_file(). Files: ez-homelab.sh.

3. New Features and Enhancements (Medium Priority - Improves Script Flexibility)
Task 3.1: Add Argument Parsing
Implement command-line argument support (e.g., using getopts or argparse if Bash allows). Support flags like --deploy-core, --deploy-additional, --install-nvidia, --dry-run, --verbose, --debug, --help. Allow bypassing the menu for automated runs.
Effort: 2-3 hours. Dependencies: None. Files: Add to main() in ez-homelab.sh.

Task 3.2: Add Dry-Run Mode
Implement --dry-run flag: Simulate deployment without making changes (e.g., validate configs, show what would be done, but don't run docker compose up). Log actions verbosely.
Effort: 2 hours. Dependencies: Argument parsing. Files: Modify perform_deployment() and related functions in ez-homelab.sh.

Task 3.3: Enhance Console Logging for Verbose Mode
Update log_* functions to output to console when VERBOSE=true (not just debug file). Ensure debug logs go to both console and file.
Effort: 1 hour. Dependencies: None. Files: ez-homelab.sh.

Task 3.4: Improve Error Handling
Change set -e to allow continuation on errors (log warnings/errors but proceed). Use || consistently for non-critical failures (e.g., network creation). Add try-catch-like logic where possible.
Effort: 2 hours. Dependencies: Review all exit 1 points. Files: ez-homelab.sh.

4. TLS and Multi-Server Logic Refinements (Medium Priority - Complex but Critical for Multi-Server)
Task 4.1: Clarify Variable Usage
Update prompts and logic to distinguish: IP_ADDRESS/SERVER_IP for local machine; REMOTE_SERVER_* for core server. Ensure ${DOMAIN} is prompted even for additional servers (as it's needed for configs). Reword setup_multi_server_tls() to emphasize cert copying from core.
Effort: 1-2 hours. Dependencies: Task 1.2. Files: ez-homelab.sh.
5. Function Organization and Code Quality (Low Priority - Refactoring for Maintainability)
Task 5.1: Audit and Improve Placeholder/Env Functions
Review replace_env_placeholders() and enhance_placeholder_replacement() for quality (e.g., handle edge cases, improve performance). Refactor if needed.
Effort: 1-2 hours. Dependencies: None. Files: ez-homelab.sh.

Task 5.2: Modularize Code with More Functions
Break main() into smaller functions (e.g., parse_args(), handle_menu_choice(), prepare_deployment()). Extract repeated logic (e.g., env copying, dir creation) into helpers.
Effort: 3-4 hours. Dependencies: All other tasks. Files: ez-homelab.sh.

Task 5.3: Fix Deployment Flow
Streamline perform_deployment(): Ensure consistent step numbering, better error recovery, and integration with dry-run.
Effort: 1 hour. Dependencies: Tasks 3.2, 3.4. Files: ez-homelab.sh.

Implementation Order and Next Steps
Start with High-Priority Tasks: Bugs (2.1-2.2) and Menu Option 1 (1.1) to fix immediate issues.
Then Core Features: Argument parsing (3.1), dry-run (3.2), and Option 4 (1.3).
Refinements: Error handling (3.4), logging (3.3), and multi-server (4.1).
Cleanup: Function organization (5.x) last, as it depends on other changes.
Testing Plan: After each task, test interactively and with args. Use dry-run for validation.
Questions for You: Confirm if install-prerequisites.sh should be in the same repo. Any specific NVIDIA installer versions to target? Should dry-run output be machine-readable (e.g., JSON)?
Let me know if you'd like me to start implementing any tasks or need more details!