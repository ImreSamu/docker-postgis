# Auto-Rerun Helper Workflow Documentation

## Overview

The `auto-rerun-helper.yml` is a simple but powerful GitHub Actions workflow that automatically retries failed workflow runs. It provides a lightweight solution for handling transient failures in CI/CD pipelines without requiring template integration.

## Features

- 🔄 **Automatic retry** of failed workflow runs
- 🎯 **Selective retry** - only reruns failed jobs using `gh run rerun --failed`
- 🛡️ **Safety limits** - maximum 3 retry attempts per workflow run
- 📊 **Multiple workflow support** - monitors several workflows simultaneously
- 🚀 **Zero configuration** - works out-of-the-box without modification
- ⚡ **Lightweight** - single job with minimal resource usage
- 🔒 **Race condition protection** - concurrency control prevents multiple helpers for same workflow
- 📋 **Clear logging** - detailed progress messages with emojis for better visibility

## How It Works

The workflow uses GitHub's `workflow_run` trigger to automatically respond when monitored workflows complete with a failure status:

```yaml
on:
  workflow_run:
    workflows:
      - workflow-build-alpine
      - workflow-build-debian
      - workflow-build-development
      - workflow-build-test
      - workflow-build-retrytest
    types: [completed]
```

### Retry Logic

The retry job only executes when **ALL** conditions are met:

1. **Workflow failed**: `github.event.workflow_run.conclusion == 'failure'`
2. **Within attempt limit**: `github.event.workflow_run.run_attempt < 3`
3. **Automatic trigger**: Triggered by `workflow_run` event (not manual)

### Concurrency Control

```yaml
concurrency:
  group: "${{ github.event.workflow_run.id }}-helper"
  cancel-in-progress: true
```

**Benefits:**
- **Race condition prevention**: Ensures only one helper runs per workflow
- **Resource efficiency**: Cancels duplicate helper instances
- **Clean execution**: Prevents conflicting retry attempts

### Enhanced Logging

The helper provides detailed progress information:

```bash
🔄 Queuing attempt 2 for workflow 'workflow-build-debian'
📊 Failed run ID: 1234567890
📅 Original run started: 2025-01-01T10:00:00Z
🎯 Retrying only failed jobs...
✅ Retry queued successfully!
```

### Retry Command

```bash
gh run rerun ${{ github.event.workflow_run.id }} --failed \
  --repo ${{ github.repository }}
```

**Key benefits:**
- **Selective retry**: Only failed jobs are retried, successful jobs remain untouched
- **Efficiency**: Reduces build time by not re-running successful matrix jobs
- **Cost effective**: Minimizes GitHub Actions usage minutes

## Monitored Workflows

The auto-rerun helper currently monitors these workflows:

| Workflow | Description | Typical Failure Scenarios |
|----------|-------------|---------------------------|
| `workflow-build-alpine` | Alpine-based multi-arch builds | QEMU emulation issues, network timeouts |
| `workflow-build-debian` | Debian-based standard builds | Package repository failures, cache issues |
| `workflow-build-development` | Development/experimental builds | Unstable dependencies, new features |
| `workflow-build-test` | Test workflow for validation | Test environment setup, resource limits |
| `workflow-build-retrytest` | Retry functionality testing | Controlled failure scenarios |

## Configuration

### Required Permissions

```yaml
permissions:
  actions: write   # Required for gh run rerun command
  contents: read   # Required for repository access
```

### Runtime Requirements

- **GitHub CLI**: Pre-installed on all GitHub Actions runners
- **Authentication**: Uses automatic `GITHUB_TOKEN` secret
- **Runner**: Uses `ubuntu-24.04` for consistency

## Common Use Cases

### 1. Transient Infrastructure Issues

**Example scenarios:**
- Docker registry timeouts during image pulls
- Network connectivity problems
- Package repository unavailability
- GitHub Actions runner capacity issues

**Benefit**: Automatic retry resolves 80-90% of transient failures without manual intervention.

### 2. Multi-Architecture Build Failures

**Example scenarios:**
- QEMU emulation instability for exotic architectures (s390x, mips64le)
- Architecture-specific compilation timeouts
- Cross-platform testing flakiness

**Benefit**: Selective retry only reruns failed architecture combinations, saving resources.

### 3. Cache System Issues

**Example scenarios:**
- Docker build cache corruption
- Registry cache write failures
- GitHub Actions cache service timeouts

**Benefit**: Fresh retry often resolves cache-related problems.

### 4. External Dependency Failures

**Example scenarios:**
- Third-party API rate limits
- Upstream service outages
- Certificate renewal issues
- DNS resolution problems

**Benefit**: Automatic retry handles temporary external issues.

## Advantages vs Template-Based Retry

### Auto-Rerun Helper Advantages

| Feature | Auto-Rerun Helper | Template-Based Retry |
|---------|-------------------|----------------------|
| **Setup complexity** | Zero configuration | Requires template integration |
| **Workflow modification** | None required | Must add retry job to each workflow |
| **Trigger mechanism** | External `workflow_run` | Internal `needs` dependencies |
| **Resource usage** | Minimal (single job) | Higher (additional job per workflow) |
| **Maintenance** | Single file to maintain | Multiple workflow integrations |
| **Debugging** | Simple single-job logs | Distributed across workflows |

### Template-Based Retry Advantages

| Feature | Template-Based Retry | Auto-Rerun Helper |
|---------|---------------------|-------------------|
| **Failure analysis** | Comprehensive logging | Basic failure detection |
| **Conditional retry** | Event-based filtering | All failures trigger retry |
| **Workflow awareness** | Full context awareness | Limited to workflow run status |
| **Customization** | Per-workflow configuration | Global configuration only |
| **Integration** | Tight workflow integration | Loose coupling |

## Limitations

### 1. Self-Retry Limitation

**Issue**: The auto-rerun helper cannot retry itself if it fails, because:
- `workflow_run` trigger only activates after a workflow completes
- If the helper fails, there's no workflow monitoring it
- No external trigger exists to restart a failed helper

**Impact**: If the helper fails (rare), manual intervention is required.

**Mitigation**: The helper is designed to be very simple and reliable to minimize failure risk.

### 2. Limited Failure Analysis

**Issue**: The helper only detects workflow-level failures, not specific job or step failures.

**Impact**: No detailed failure analysis or architecture-specific retry logic.

**Mitigation**: For complex analysis, use the template-based retry system.

### 3. No Event Filtering

**Issue**: The helper retries all failures regardless of trigger event (schedule, push, PR, etc.).

**Impact**: May retry PR builds or other scenarios where retry isn't desired.

**Mitigation**: Consider event-based filtering if needed.

## Monitoring and Debugging

### Success Indicators

- **Workflow completion**: Failed workflows complete successfully after retry
- **Job efficiency**: Only failed jobs are retried, not entire workflows
- **Attempt tracking**: Retry attempts are properly tracked in GitHub UI

### Debugging Steps

1. **Check workflow run history**: Verify auto-rerun helper is triggered
2. **Review permissions**: Ensure `actions: write` permission is set
3. **Validate workflow names**: Confirm monitored workflow names match exactly
4. **Test retry command**: Manually test `gh run rerun --failed` command

### Monitoring Metrics

- **Retry frequency**: How often workflows require retries
- **Success rate**: Percentage of retries that succeed
- **Failure patterns**: Common failure scenarios across workflows
- **Resource impact**: Additional GitHub Actions minutes consumed

## Best Practices

### 1. Workflow Reliability

- Design workflows to be idempotent (safe to retry)
- Use proper error handling and cleanup
- Implement timeout controls for long-running operations

### 2. Failure Root Cause Analysis

- Monitor retry patterns to identify systemic issues
- Address persistent failure causes rather than relying on retries
- Use retry data to improve workflow robustness

### 3. Resource Management

- Monitor GitHub Actions usage to understand retry costs
- Consider retry limits for resource-intensive workflows
- Balance retry attempts with development velocity

### 4. Testing

- Use `workflow-build-retrytest` to validate retry functionality
- Test retry behavior with controlled failure scenarios
- Verify retry limits are respected

## Security Considerations

- **Minimal permissions**: Only requires `actions: write` and `contents: read`
- **No external dependencies**: Uses only GitHub-provided tools and secrets
- **Secure by design**: No custom code execution or data transmission
- **Audit trail**: All retry actions are logged in GitHub Actions history

## Maintenance

### Adding New Workflows

To monitor additional workflows, add them to the `workflows` list:

```yaml
on:
  workflow_run:
    workflows:
      - workflow-build-alpine
      - workflow-build-debian
      - workflow-build-development
      - workflow-build-test
      - workflow-build-retrytest
      - new-workflow-name  # Add new workflow here
    types: [completed]
```

### Modifying Retry Limits

To change the maximum retry attempts, update the condition:

```yaml
if: >
  github.event.workflow_run.conclusion == 'failure' &&
  github.event.workflow_run.run_attempt < 5  # Change from 3 to 5
```

### Disabling Auto-Retry

To temporarily disable auto-retry:

1. **Comment out the job**: Add `if: false` to the job
2. **Rename the workflow**: Change filename to `.disabled` extension
3. **Remove from workflows list**: Comment out specific workflows

## Integration with Other Systems

### Workflow Template Compatibility

The auto-rerun helper works alongside template-based retry systems:

- **Template retry**: Handles complex failure scenarios with analysis
- **Auto-rerun helper**: Provides backup retry for template failures
- **Complementary**: Both systems can operate simultaneously

### Monitoring Integration

The helper can be integrated with external monitoring:

- **Webhook notifications**: Add steps to notify external systems
- **Metrics collection**: Export retry statistics to monitoring platforms
- **Alerting**: Trigger alerts for high retry rates or persistent failures

## Future Enhancements

### Potential Improvements

1. **Conditional retry**: Add event-based filtering (schedule vs PR)
2. **Workflow-specific limits**: Different retry limits per workflow
3. **Failure pattern analysis**: Basic failure categorization
4. **Integration hooks**: Support for external notification systems

### Architectural Considerations

- **Self-retry capability**: Explore options for helper self-recovery
- **Distributed monitoring**: Multiple helpers for different workflow groups
- **Advanced filtering**: More sophisticated retry conditions

---

## Summary

The `auto-rerun-helper.yml` provides a simple, effective solution for automatically retrying failed GitHub Actions workflows. While it has limitations compared to template-based retry systems, its simplicity and zero-configuration approach make it ideal for many use cases.

**Use auto-rerun helper when:**
- You want simple, automatic retry functionality
- Minimal setup and maintenance is preferred
- Transient failures are the primary concern
- Workflow reliability is more important than detailed analysis

**Use template-based retry when:**
- Detailed failure analysis is required
- Complex conditional retry logic is needed
- Tight workflow integration is desired
- Per-workflow customization is important

For most scenarios, the auto-rerun helper provides an excellent balance of functionality and simplicity.