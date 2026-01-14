# Round 6 Testing - Agent Instructions for Script Optimization

## Mission Context
Test and optimize the AI-Homelab deployment scripts ([setup-homelab.sh](scripts/setup-homelab.sh) and [deploy-homelab.sh](scripts/deploy-homelab.sh)) on a **test server** environment. Focus on improving repository code quality and reliability, not test server infrastructure.

## Current Status - Round 6
- **Test Environment**: Fresh Debian installation
- **Testing Complete**: ✅ Both scripts now working successfully
- **Issues Fixed**:
  - Password hash extraction from Authelia output (added proper parsing)
  - Credential flow between setup and deploy scripts (saved plain password)
  - Directory vs file conflicts on re-runs (added cleanup logic)
  - Authelia database encryption key mismatches (added auto-cleanup)
  - Password display for user reference (now shows and saves password)
- **Previous Rounds**: 1-5 focused on permission handling, deployment order, and stability

## Primary Objectives

### 1. Script Reliability Analysis
- [ ] Identify why setup-homelab.sh failed during Authelia password hash generation
- [ ] Review error handling and fallback mechanisms
- [ ] Check Docker availability before container-based operations
- [ ] Validate all external dependencies (curl, openssl, docker)

### 2. Repository Improvements (Priority Focus)
- [ ] Enhance error messages with actionable debugging steps
- [ ] Add pre-flight validation checks before critical operations
- [ ] Improve script idempotency (safe to run multiple times)
- [ ] Add progress indicators for long-running operations
- [ ] Document assumptions and prerequisites more clearly

### 3. Testing Methodology
- [ ] Create test checklist for each script function
- [ ] Document expected vs. actual behavior at failure point
- [ ] Test edge cases (partial runs, re-runs, missing dependencies)
- [ ] Verify scripts work on truly fresh Debian installation

## Critical Operating Principles

### DO Focus On (Repository Optimization)
✅ **Script robustness**: Better error handling, validation, recovery
✅ **User experience**: Clear messages, progress indicators, helpful errors
✅ **Documentation**: Update docs to match actual script behavior
✅ **Idempotency**: Scripts can be safely re-run without breaking state
✅ **Dependency checks**: Validate requirements before attempting operations
✅ **Rollback capability**: Provide recovery steps when operations fail

### DON'T Focus On (Test Server Infrastructure)
❌ **Test server setup**: Don't modify the test server's base configuration
❌ **System packages**: Test scripts should work with standard Debian
❌ **Hardware setup**: Focus on software reliability, not hardware optimization
❌ **Performance tuning**: Prioritize reliability over speed

## Specific Issues to Address (Round 6)

### Issue 1: Authelia Password Hash Generation Failure
**Problem**: Script failed while generating password hash using Docker container

**Investigation Steps**:
1. Check if Docker daemon is running before attempting container operations
2. Verify Docker image pull capability (network connectivity)
3. Add timeout handling for Docker run operations
4. Provide fallback mechanism if Docker-based hash generation fails

**Proposed Solutions**:
```bash
# Option 1: Pre-validate Docker availability
if ! docker info &> /dev/null 2>&1; then
    log_error "Docker is not available for password hash generation"
    log_info "This requires Docker to be running. Please ensure:"
    log_info "  1. Docker daemon is started: sudo systemctl start docker"
    log_info "  2. User can access Docker: docker ps"
    exit 1
fi

# Option 2: Add timeout and error handling
log_info "Generating password hash (this may take a moment)..."
if ! PASSWORD_HASH=$(timeout 30 docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password "$ADMIN_PASSWORD" 2>&1 | grep '^\$argon2'); then
    log_error "Failed to generate password hash"
    log_info "Error output:"
    echo "$PASSWORD_HASH"
    log_info ""
    log_info "Troubleshooting steps:"
    log_info "  1. Check Docker is running: docker ps"
    log_info "  2. Test image pull: docker pull authelia/authelia:4.37"
    log_info "  3. Check network connectivity"
    exit 1
fi

# Option 3: Provide manual hash generation instructions
if [ -z "$PASSWORD_HASH" ]; then
    log_error "Automated hash generation failed"
    log_info ""
    log_info "You can generate the hash manually after setup:"
    log_info "  docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2"
    log_info "  Then edit: /opt/stacks/core/authelia/users_database.yml"
    log_info ""
    read -p "Continue without setting admin password now? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    # Set placeholder that requires manual configuration
    PASSWORD_HASH="\$argon2id\$v=19\$m=65536,t=3,p=4\$CHANGEME"
fi
```

### Issue 2: Script Exit Codes and Error Recovery

**Problem**: Script exits on first error without cleanup or recovery guidance

**Improvements**:
```bash
# Add at script beginning
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failures

# Add trap for cleanup on error
cleanup_on_error() {
    local exit_code=$?
    log_error "Script failed with exit code: $exit_code"
    log_info ""
    log_info "Partial setup may have occurred. To resume:"
    log_info "  1. Review error messages above"
    log_info "  2. Fix the issue if possible"
    log_info "  3. Re-run: sudo ./setup-homelab.sh"
    log_info ""
    log_info "The script is designed to be idempotent (safe to re-run)"
}

trap cleanup_on_error ERR
```

### Issue 3: Pre-flight Validation

**Add comprehensive checks before starting**:
```bash
# New Step 0: Pre-flight validation
log_info "Step 0/9: Running pre-flight checks..."

# Check internet connectivity
if ! ping -c 1 8.8.8.8 &> /dev/null && ! ping -c 1 1.1.1.1 &> /dev/null; then
    log_error "No internet connectivity detected"
    log_info "Internet access is required for:"
    log_info "  - Installing packages"
    log_info "  - Downloading Docker images"
    log_info "  - Accessing Docker Hub"
    exit 1
fi

# Check DNS resolution
if ! nslookup google.com &> /dev/null; then
    log_warning "DNS resolution may be impaired"
fi

# Check disk space
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
REQUIRED_SPACE=5000000  # 5GB in KB
if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    log_error "Insufficient disk space"
    log_info "Available: $(($AVAILABLE_SPACE / 1024))MB"
    log_info "Required: $(($REQUIRED_SPACE / 1024))MB"
    exit 1
fi

log_success "Pre-flight checks passed"
echo ""
```

## Testing Checklist for Round 6

### setup-homelab.sh Testing
- [ ] **Clean run**: Fresh Debian 12 system with no prior setup
- [ ] **Re-run safety**: Run script twice, verify idempotency
- [ ] **Interrupted run**: Stop script mid-execution, verify recovery
- [ ] **Network failure**: Simulate network issues during package installation
- [ ] **Docker unavailable**: Test behavior when Docker daemon isn't running
- [ ] **User input validation**: Test invalid inputs (weak passwords, invalid emails)
- [ ] **NVIDIA skip**: Test skipping GPU driver installation
- [ ] **NVIDIA install**: Test GPU driver installation path (if hardware available)

### deploy-homelab.sh Testing
- [ ] **Missing .env**: Test behavior when .env file doesn't exist
- [ ] **Invalid .env**: Test with incomplete or malformed .env values
- [ ] **Port conflicts**: Test when ports 80/443 are already in use
- [ ] **Network issues**: Simulate Docker network creation failures
- [ ] **Core stack failure**: Test recovery if core services fail to start
- [ ] **Certificate generation**: Monitor Let's Encrypt certificate acquisition
- [ ] **Re-deployment**: Test redeploying over existing infrastructure
- [ ] **Partial deployment**: Stop mid-deployment, verify recovery

## Documentation Updates Required

### 1. Update [docs/getting-started.md](docs/getting-started.md)
- Document actual script behavior observed in testing
- Add troubleshooting section for common failure scenarios
- Include recovery procedures for partial deployments
- Update Round 4 → Round 6 references

### 2. Update [AGENT_INSTRUCTIONS.md](AGENT_INSTRUCTIONS.md)
- Change "Round 4" references to current round
- Add learnings from Round 5 and 6 testing
- Document new error handling patterns
- Update success criteria

### 3. Create Testing Guide
- Document test environment setup
- Provide test case templates
- Include expected vs actual result tracking
- Create test automation scripts if beneficial

## Agent Action Workflow

### Phase 1: Analysis (30 minutes)
1. Review last terminal output to identify exact failure point
2. Read relevant script sections around the failure
3. Check for similar issues in previous rounds (git history)
4. Document root cause and contributing factors

### Phase 2: Solution Design (20 minutes)
1. Propose specific code changes to address issues
2. Design error handling and recovery mechanisms
3. Create validation checks to prevent recurrence
4. Draft user-facing error messages

### Phase 3: Implementation (40 minutes)
1. Apply changes to scripts using multi_replace_string_in_file
2. Update related documentation
3. Add comments explaining complex error handling
4. Update .env.example if new variables needed

### Phase 4: Validation (30 minutes)
1. Review script syntax: `bash -n scripts/*.sh`
2. Check for common shell script issues (shellcheck if available)
3. Verify all error paths have recovery guidance
4. Test modified sections in isolation if possible

### Phase 5: Documentation (20 minutes)
1. Update CHANGELOG or version notes
2. Document breaking changes if any
3. Update README if testing procedure changed
4. Create/update this round's testing summary

## Success Criteria for Round 6

### Must Have
- ✅ setup-homelab.sh completes successfully on fresh Debian 12
- ✅ Script provides clear error messages when failures occur
- ✅ All error conditions have recovery/troubleshooting guidance
- ✅ Scripts can be safely re-run without breaking existing setup
- ✅ Docker availability validated before Docker operations

### Should Have
- ✅ Pre-flight validation catches issues before they cause failures
- ✅ Progress indicators show user what's happening
- ✅ Timeout handling prevents infinite hangs
- ✅ Network failures provide helpful next steps
- ✅ Documentation updated to match current behavior

### Nice to Have
- ⭐ Automated testing framework for scripts
- ⭐ Rollback capability for partial deployments
- ⭐ Log collection for debugging
- ⭐ Summary report at end of execution
- ⭐ Colored output supports colorless terminals

## Key Files to Modify

### Primary Targets
1. [scripts/setup-homelab.sh](scripts/setup-homelab.sh) - Lines 1-491
   - Focus areas: Steps 7 (Authelia secrets), error handling
2. [scripts/deploy-homelab.sh](scripts/deploy-homelab.sh) - Lines 1-340
   - Focus areas: Pre-flight checks, error recovery
3. [AGENT_INSTRUCTIONS.md](AGENT_INSTRUCTIONS.md) - Round references
4. [docs/getting-started.md](docs/getting-started.md) - Testing documentation

### Supporting Files
- [.env.example](.env.example) - Validate all variables documented
- [README.md](README.md) - Update if quick start changed
- [docs/quick-reference.md](docs/quick-reference.md) - Add troubleshooting entries

## Constraints and Guidelines

### Follow Repository Standards
- Maintain existing code style and conventions
- Use established logging functions (log_info, log_error, etc.)
- Keep user-facing messages clear and actionable
- Preserve idempotency where it exists

### Avoid Scope Creep
- Don't rewrite entire scripts - make targeted improvements
- Don't add features - focus on fixing reliability issues
- Don't optimize performance - focus on correctness
- Don't modify test server - fix repository code

### Safety First
- All changes must maintain backward compatibility
- Don't remove existing functionality
- Add validation, don't skip steps
- Provide rollback/recovery for all operations

## Communication with User

### Regular Updates
- Report progress through testing phases
- Highlight blockers or unexpected findings
- Ask for clarification when needed
- Summarize changes made

### Final Report Format
```markdown
# Round 6 Testing Summary

## Issues Identified
1. [Issue name] - [Brief description]
   - Root cause: ...
   - Impact: ...

## Changes Implemented
1. [File]: [Change description]
   - Why: ...
   - Testing: ...

## Testing Results
- ✅ [What works]
- ⚠️ [What needs attention]
- ❌ [What still fails]

## Next Steps for Round 7
1. [Remaining issue to address]
2. [Enhancement to consider]
```

---

## Immediate Actions for Agent

1. **Investigate current failure**:
   - Review terminal output showing exit code 1
   - Identify line in setup-homelab.sh where failure occurred
   - Determine if Docker was available for password hash generation

2. **Propose specific fixes**:
   - Add Docker availability check before Authelia password hash step
   - Add timeout handling for docker run command
   - Provide fallback if automated hash generation fails

3. **Implement improvements**:
   - Update setup-homelab.sh with error handling
   - Add pre-flight validation checks
   - Enhance error messages with recovery steps

4. **Update documentation**:
   - Document Round 6 findings
   - Update troubleshooting guide
   - Revise Round 4 references to current round

5. **Prepare for validation**:
   - Create test checklist
   - Document expected behavior
   - Note any manual testing steps needed

---

*Generated for Round 6 testing of AI-Homelab deployment scripts*
*Focus: Repository optimization, not test server modification*
