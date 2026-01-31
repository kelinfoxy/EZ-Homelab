# EZ-Homelab Script Fixes & Improvements

## Critical Fixes (Implement First)
- [x] **Secret Validation**: Add validation after `save_env_file()` to ensure Authelia secrets exist before deployment
- [x] **Better Placeholder Error Handling**: Make `replace_env_placeholders()` fail deployment if critical variables are missing
- [x] **Debug Logging**: Add toggleable comprehensive logging to file for troubleshooting
- [x] **Simplified Placeholder Logic**: Streamline the replacement process in `deploy_core()`
- [x] **Standardized .env Placeholders**: Update .env.example and .env with consistent placeholder format
- [x] **File Permission Issues**: Fix ownership problems when copying files as root then accessing as user
- [x] **REMOTE_SERVER_HOSTNAME Error**: Remove multi-server config files from core deployments to prevent critical errors
- [x] **Docker Compose Variable Expansion**: Remove AUTHELIA_ADMIN_PASSWORD from core stack .env to prevent argon2id hash expansion warnings

## High Priority Issues
- [ ] **Authelia Password Hash Generation Reliability**
  - Issue: Docker-based password hash generation can fail if Docker isn't ready or Authelia image pull fails
  - Impact: Deployment fails with cryptic errors
  - Fix: Add retry logic and fallback to local hash generation

- [x] **Environment Variable Persistence Issues**
  - Issue: Timing issues with when .env is sourced vs when variables are needed
  - Impact: Variables not available when functions expect them
  - Fix: Implemented safe .env loading that doesn't expand special characters + filtered .env files per stack

## Medium Priority Issues
- [ ] **Multi-Server TLS Setup Complexity**
  - Issue: Complex SSH authentication logic with multiple failure points
  - Impact: TLS setup often fails, preventing remote Docker access
  - Fix: Simplify to use SSH config files and better error messages

- [ ] **Directory Permission Race Conditions**
  - Issue: Script creates directories with sudo then writes as regular user
  - Impact: Permission conflicts during file operations
  - Fix: Consistent ownership handling throughout

- [ ] **Missing Pre-deployment Validation**
  - Issue: No comprehensive checks before starting deployment
  - Impact: Failures occur mid-deployment after time investment
  - Fix: Add validation phase checking Docker, networks, environment

## Low Priority Issues
- [ ] **Function Complexity**
  - Issue: Large functions like `deploy_core()` and `prompt_for_values()` are hard to test/debug
  - Impact: Bugs are harder to isolate and fix
  - Fix: Break down into smaller, focused functions

- [ ] **No Rollback Capability**
  - Issue: Failed deployments leave partial state
  - Impact: Manual cleanup required, risk of inconsistent state
  - Fix: Add cleanup functions for failed deployments

## Implementation Notes
- Start with Critical Fixes to make Option 2 deployment reliable
- Test each fix individually before moving to next
- Use debug logging to validate fixes work correctly
- Update documentation after each major change
- Consider backward compatibility with existing deployments