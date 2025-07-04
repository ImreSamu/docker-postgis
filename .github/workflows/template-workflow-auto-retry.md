# Auto-Retry Template Documentation

## Overview

The `template-workflow-auto-retry.yml` is a reusable GitHub Actions workflow template that provides automatic retry functionality for failed workflow jobs. It includes comprehensive failure analysis, detailed logging, and configurable retry behavior.

## Features

- 🔄 **Automatic retry** of failed jobs using GitHub CLI
- 📊 **Detailed failure analysis** with comprehensive logging
- 🏗️ **Architecture-specific statistics** for multi-arch builds
- ⏱️ **Timing and cost analysis** with billable time breakdown
- 🎯 **Configurable parameters** for different workflow types
- 🛡️ **Safety controls** with maximum attempt limits
- 🎨 **Workflow-specific customization** with emojis and branding

## Template Parameters

### Required Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `workflow_name` | string | Name of the parent workflow | `"Alpine"`, `"Debian"` |
| `job_names` | string | JSON array of job names to track | `'["job1", "job2"]'` |
| `workflow_cache_id` | string | Workflow cache identifier | `"alp"`, `"deb"`, `"dev"`, `"tst"` |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `workflow_emoji` | string | `"🔄"` | Emoji for workflow branding |
| `max_attempts` | number | `3` | Maximum retry attempts |
| `enable_detailed_logging` | boolean | `true` | Enable comprehensive failure analysis |

## Usage Examples

### Alpine Workflow Integration

```yaml
# workflow-build-alpine.yml
permissions:
  actions: write
  contents: read

jobs:
  # ... existing jobs ...

  auto-retry-failed:
    name: "🔄 Auto-retry failed Alpine builds"
    needs:
      - alpine-8arch-recent
      - alpine-8arch-legacy
      - alpine-2arch-3-22-3-6
      - alpine-2arch-3-22-3-4
      - alpine-2arch-3-21-3-5
      - alpine-2arch-3-21-3-4
      - alpine-2arch-3-21-3-3
    uses: ./.github/workflows/template-workflow-auto-retry.yml
    with:
      workflow_name: "Alpine"
      workflow_emoji: "🏔️"
      job_names: '["alpine-8arch-recent", "alpine-8arch-legacy", "alpine-2arch-3-22-3-6", "alpine-2arch-3-22-3-4", "alpine-2arch-3-21-3-5", "alpine-2arch-3-21-3-4", "alpine-2arch-3-21-3-3"]'
      workflow_cache_id: "alp"
      max_attempts: 3
      enable_detailed_logging: true
```

### Debian Workflow Integration

```yaml
# workflow-build-debian.yml
auto-retry-failed:
  name: "🔄 Auto-retry failed Debian builds"
  needs:
    - bookworm
    - bullseye
    - bundle0
  uses: ./.github/workflows/template-workflow-auto-retry.yml
  with:
    workflow_name: "Debian"
    workflow_emoji: "📦"
    job_names: '["bookworm", "bullseye", "bundle0"]'
    workflow_cache_id: "deb"
    max_attempts: 3
    retry_events: "schedule,workflow_dispatch"
    enable_detailed_logging: true
```

### Test Workflow Integration

```yaml
# workflow-build-test.yml
auto-retry-failed:
  name: "🔄 Auto-retry failed Test builds"
  needs:
    - test-critical
  uses: ./.github/workflows/template-workflow-auto-retry.yml
  with:
    workflow_name: "Test"
    workflow_emoji: "🧪"
    job_names: '["test-critical"]'
    workflow_cache_id: "tst"
    max_attempts: 3
    enable_detailed_logging: true
```

## Workflow Configuration Summary

| Workflow | Emoji | Jobs | Cache ID | Use Case |
|----------|-------|------|----------|----------|
| **Alpine** | 🏔️ | 7 sequential jobs | `alp` | Complex multi-step pipeline |
| **Debian** | 📦 | 3 jobs with dependencies | `deb` | Standard production builds |
| **Development** | 🔧 | 3 sequential jobs | `dev` | Experimental/dev builds |
| **Test** | 🧪 | 1 job | `tst` | Template testing & validation |

## Detailed Logging Output

When `enable_detailed_logging: true`, the template provides:

### 1. Workflow Overview
```
🏔️ ===== ALPINE WORKFLOW FAILURE ANALYSIS =====
📊 Run ID: 1234567890
🔢 Attempt: 2/3
📅 Started: 2025-01-01T10:00:00Z
🏷️ Event: schedule
🌿 Branch: manifest
🗂️ Cache ID: alp
👤 Actor: github-actions[bot]
```

### 2. Job Status Breakdown
```
🏔️ ===== JOB STATUS BREAKDOWN =====
📋 Job: alpine-8arch-recent
   Status: completed
   Conclusion: success
   Started: 2025-01-01T10:00:00Z
   Completed: 2025-01-01T10:15:00Z
   URL: https://github.com/repo/actions/runs/123/job/456

📋 Job: alpine-8arch-legacy
   Status: completed  
   Conclusion: failure
   Started: 2025-01-01T10:15:00Z
   Completed: 2025-01-01T10:30:00Z
   URL: https://github.com/repo/actions/runs/123/job/789
```

### 3. Failed Jobs Analysis
```
🏔️ ===== FAILED JOBS DETAILED =====
❌ FAILED: alpine-8arch-legacy
   Started: 2025-01-01T10:15:00Z
   Completed: 2025-01-01T10:30:00Z
   Runner: ubuntu-24.04-arm
   URL: https://github.com/repo/actions/runs/123/job/789
```

### 4. Architecture Failure Statistics
```
🏔️ ===== ARCHITECTURE FAILURE STATS =====
🏗️ amd64: 0 failures
🏗️ arm64: 2 failures
🏗️ armv6: 1 failures
🏗️ armv7: 1 failures
🏗️ 386: 0 failures
🏗️ ppc64le: 0 failures
🏗️ riscv64: 1 failures
🏗️ s390x: 0 failures
```

### 5. Timing and Cost Analysis
```
🏔️ ===== WORKFLOW TIMING ANALYSIS =====
⏱️ Total Duration: 1800s
🚀 Billable Time:
   UBUNTU: 3600s
   UBUNTU_ARM: 1800s
```

### 6. Failure Summary
```
🏔️ ===== FAILURE SUMMARY =====
❌ Failed jobs: 3
📊 Total jobs: 7
📈 Success rate: 57.1%
```

## Retry Logic

### Trigger Conditions

The retry job only runs when **ALL** of these conditions are met:

1. **Any job failed**: `failure()` condition
2. **Within attempt limit**: `github.run_attempt < max_attempts`
3. **Allowed event type**: Event is in `retry_events` list

### Retry Behavior

- **Selective retry**: Only failed jobs are retried using `gh run rerun --failed`
- **Successful jobs**: Remain untouched and don't re-run
- **Matrix jobs**: Only failed matrix combinations are retried
- **Dependencies**: Dependency chains are preserved during retry

### Safety Features

- **Maximum attempts**: Default 3 attempts (configurable)
- **Event filtering**: Only retry on specified events (e.g., not on PR)
- **Fail-safe**: If retry command fails, workflow stops gracefully

## Requirements

### Permissions

The calling workflow must include these permissions:

```yaml
permissions:
  actions: write    # Required for gh run rerun command
  contents: read    # Required for repository access
```

### GitHub CLI

- GitHub CLI (`gh`) is pre-installed on all GitHub Actions runners
- Uses `GITHUB_TOKEN` secret (automatically available)
- No additional setup required

## Common Use Cases

### 1. Transient Infrastructure Issues
- Docker registry timeouts
- Network connectivity problems
- Runner availability issues
- Package repository failures

### 2. Multi-Architecture Builds
- QEMU emulation instability
- Architecture-specific compilation issues
- Cross-platform testing failures

### 3. Long-Running Workflows
- Cache system timeouts
- Resource exhaustion
- Time-based service limits

### 4. External Dependencies
- Third-party API rate limits
- Upstream service outages
- Certificate renewal issues

## Best Practices

### 1. Retry Event Logic

Retry is **hardcoded** to trigger only on:
- `schedule` events (automated builds)
- `workflow_dispatch` events (manual triggers)

This prevents unnecessary retries on PR pushes while ensuring production reliability.

### 2. Attempt Limits

```yaml
# Standard workflows
max_attempts: 3

# Critical/complex workflows
max_attempts: 5

# Fast feedback loops
max_attempts: 2
```

### 3. Logging Configuration

```yaml
# Production (detailed analysis needed)
enable_detailed_logging: true

# Simple workflows (minimal output)
enable_detailed_logging: false
```

### 4. Workflow Dependencies

Always include **ALL** workflow jobs in the `needs` section:

```yaml
# ✅ Correct - includes all jobs
needs:
  - job1
  - job2  
  - job3

# ❌ Incorrect - missing dependencies
needs:
  - job1
```

## Troubleshooting

### Common Issues

1. **Permission denied**: Ensure `actions: write` permission is set
2. **Missing dependencies**: Include all jobs in `needs` section
3. **Event filtering**: Only `schedule` and `workflow_dispatch` events trigger retry
4. **Attempt limit**: Verify `github.run_attempt < max_attempts`

### Debug Steps

1. Check workflow permissions
2. Verify job names match exactly
3. Confirm event type is allowed
4. Review attempt count
5. Check GitHub CLI authentication

### Monitoring

- Monitor retry frequency to identify persistent issues
- Review architecture failure patterns
- Track billable time impact
- Analyze success rate improvements

## Security Considerations

- Uses only GitHub-provided tokens (`GITHUB_TOKEN`)
- No external API calls or data transmission
- Respects GitHub Actions security boundaries
- Follows principle of least privilege

## Version History

- **v1.0**: Initial template with basic retry functionality
- **v1.1**: Added comprehensive failure analysis and logging
- **v1.2**: Enhanced architecture statistics and timing analysis
- **v1.3**: Improved configurability and safety features

---

For implementation examples and current usage, see the adapted workflow files:
- `workflow-build-alpine.yml`
- `workflow-build-debian.yml`
- `workflow-build-development.yml`
- `workflow-build-test.yml`