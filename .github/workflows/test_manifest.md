# Multi-Architecture Docker Manifest Test Workflow

This document describes the `test_manifest.yml` GitHub Actions workflow, which builds and tests multi-architecture Docker images for PostGIS containers.

## Overview

The workflow implements a sophisticated multi-architecture Docker build system that:
- Builds Docker images for multiple CPU architectures (amd64, arm64, etc.)
- Creates multi-architecture manifests for unified image distribution
- Provides comprehensive testing and validation
- Uses emoji-based job naming for improved UI readability

## Architecture Support

The workflow currently supports these architectures with their corresponding emojis for UI clarity and regression testing modes:

| Architecture | Docker Platform | Runner | Emoji | Regression Mode | Build Type | Optimization | Use Case |
|--------------|-----------------|--------|-------|-----------------|------------|-------------|----------|
| amd64        | linux/amd64     | ubuntu-24.04 | 💻 | require | native ⚡ | -O3 -Wall -fno-omit-frame-pointer -Werror | Intel/AMD 64-bit (Production) |
| arm64        | linux/arm64     | ubuntu-24.04-arm | 💪 | require | native ⚡ | -O3 -Wall -fno-omit-frame-pointer -Werror | Apple Silicon, AWS Graviton (Production) |
| armv6        | linux/arm/v6    | ubuntu-24.04-arm | 🦾 | test | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer -Werror | Raspberry Pi Zero (Experimental) |
| armv7        | linux/arm/v7    | ubuntu-24.04-arm | 🤖 | test | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer -Werror | Raspberry Pi 2/3/4 (Experimental) |
| 386          | linux/386       | ubuntu-24.04 | 🖥️ | test | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer -Werror | Legacy 32-bit Intel (Experimental) |
| mips64le     | linux/mips64le  | ubuntu-24.04 | 🎯 | skip | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer -Werror | MIPS 64-bit systems (Skip Tests) |
| ppc64le      | linux/ppc64le   | ubuntu-24.04 | ⚡ | test | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer -Werror | IBM POWER systems (Experimental) |
| riscv64      | linux/riscv64   | ubuntu-24.04 | 🧩 | test_nojit | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer -Werror | RISC-V 64-bit (No-JIT) |
| s390x        | linux/s390x     | ubuntu-24.04 | 🏢 | skip | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer -Werror | IBM mainframes (Skip Tests) |

## Configuration

### Environment Variables

#### Core Settings
- `REGISTRY`: Docker registry (default: `docker.io`)
- `REPO_NAME`: Repository name (default: `imresamu`)
- `IMAGE_NAME`: Base image name (default: `postgistest`)
- `TARGET_BRANCH`: Branch for automated builds (default: `manifest` for testing, change to `master` for production)

#### Architecture Configuration
- `SUPPORTED_ARCHITECTURES`: JSON array of active architectures
- `ARCH_RUNNERS`: Maps architectures to GitHub runner types
- `ARCH_PLATFORMS`: Maps architectures to Docker platform strings
- `ARCH_EMOJIS`: Maps architectures to emoji icons for UI
- `ARCH_REGRESSION_MODES`: Maps architectures to regression testing modes (skip/test/test_nojit/require)
- `REGRESSION_MODE_EMOJIS`: Maps regression modes to emoji representations
- `BUILD_TYPE_EMOJIS`: Maps build types (native/qemu) to emoji representations  
- `ARCH_NATIVE_BUILDS`: Maps architectures to build types (native vs qemu)
- `ARCH_OPTIMIZATION_FLAGS`: Maps architectures to compiler optimization flags
- `ARCH_ANNOTATIONS`: Maps architectures to manifest annotation metadata

#### Image Configuration
- `IMAGE_DIRECTORIES`: JSON array of directories to build (auto-updated by `tools/apply-ci.sh`)

### Adding New Architectures

To add support for new architectures:

1. **Add to `SUPPORTED_ARCHITECTURES`**:
   ```yaml
   SUPPORTED_ARCHITECTURES: '["amd64", "arm64", "new_arch"]'
   ```

2. **Configure mappings** in all architecture mapping objects:
   ```yaml
   ARCH_RUNNERS: '{"new_arch": "ubuntu-24.04"}'
   ARCH_PLATFORMS: '{"new_arch": "linux/new_arch"}'
   ARCH_EMOJIS: '{"new_arch": "🔥"}'
   ARCH_REGRESSION_MODES: '{"new_arch": "test"}'
   ARCH_NATIVE_BUILDS: '{"new_arch": "qemu"}'
   ARCH_OPTIMIZATION_FLAGS: '{"new_arch": "-O1"}'
   ARCH_ANNOTATIONS: '{"new_arch": {"os": "linux", "arch": "new_arch"}}'
   ```

3. **No code changes required** - the workflow dynamically generates the build matrix

## Regression Testing Modes

The workflow supports four regression testing modes for PostGIS builds:

### Mode Descriptions

| Mode | Description | Behavior | JIT Setting | Log Storage | Use Case |
|------|-------------|----------|-------------|-------------|----------|
| `skip` | No regression tests | Tests are completely skipped | N/A | None | Fast builds, debugging |
| `test` | Non-blocking tests | Tests run but failures don't fail the build | Enabled | Compressed with zstd --long | Development, experimental architectures |
| `test_nojit` | Non-blocking tests without JIT | Tests run with JIT disabled, failures don't fail build | Disabled + Config Modified | Compressed with zstd --long | JIT-incompatible architectures |
| `require` | Blocking tests | Tests must pass or build fails | Enabled | None (tests must pass) | Production architectures |

### Emoji Representations

| Mode | Emoji | Meaning |
|------|-------|---------|
| `skip` | 💨 | Fast/skip |
| `test` | 🔍 | Investigation/search |
| `test_nojit` | 🔍🐢 | Investigation + slow (no JIT) |
| `require` | 🔒 | Locked/required |

### Build Type Indicators

| Type | Emoji | Meaning |
|------|-------|---------|
| `native` | ⚡ | Fast/native execution |
| `qemu` | 🔄 | Emulated/cross-compilation |

### Architecture-Specific Modes

- **Production Architectures** (`amd64`, `arm64`): Use `require` mode
  - Tests must pass for build to succeed
  - Native execution with JIT enabled
  - Ensures production image quality
  - No log storage needed (tests pass or build fails)

- **Standard Experimental Architectures** (`armv6`, `armv7`, `386`, `ppc64le`): Use `test` mode  
  - Tests run to catch issues early with JIT enabled
  - Build continues even if tests fail
  - Regression logs saved compressed for debugging
  - Enables development on new architectures

- **JIT-Incompatible Architectures** (`riscv64`): Use `test_nojit` mode
  - Tests run with JIT disabled for compatibility
  - Build continues even if tests fail
  - Server restart ensures clean state after potentially failed regression tests
  - Extension testing performed with JIT disabled
  - PostgreSQL configuration modified to disable JIT by default for end users
  - Regression logs saved compressed for debugging

- **Most Problematic Architectures** (`mips64le`, `s390x`): Use `skip` mode
  - No regression tests run at all
  - Focus on successful PostGIS compilation and installation
  - Fastest build times for these challenging architectures
  - No log storage needed (no tests executed)

### Log Management

For `test` and `test_nojit` modes, regression test logs are:
- Captured during build execution (visible in build output)
- Compressed using `zstd -3 --long` for optimal size
- Stored as `/_pgis_regression_test.log.zst` in the final image
- Can be extracted with: `zstd -dc /_pgis_regression_test.log.zst`

### Job Naming Convention

The workflow uses a compact naming format that includes all key information:

**Format**: `{arch_emoji}{arch_name}|{regression_emoji}{image_dir}{build_type_emoji}`

**Examples**:
- `💻amd64|🔒17-3.5/alpine3.22⚡` - Native amd64, required tests
- `💪arm64|🔒17-3.5/alpine3.22⚡` - Native arm64, required tests  
- `🦾armv6|🔍17-3.5/alpine3.22🔄` - QEMU armv6, standard test mode
- `🧩riscv64|🔍🐢17-3.5/alpine3.22🔄` - QEMU riscv64, no-JIT test mode
- `🎯mips64le|🔍🐢17-3.5/alpine3.22🔄` - QEMU mips64le, no-JIT test mode

### Template Integration

The regression testing is controlled via Dockerfile template build argument:
```dockerfile
ARG PGIS1_REGRESSION_MODE=require
```

This argument is automatically set by the workflow based on the architecture being built. Valid values are:
- `skip`: No regression tests
- `test`: Standard regression tests with JIT enabled
- `test_nojit`: Regression tests with JIT disabled for compatibility, also modifies postgresql.conf.sample to disable JIT by default
- `require`: Mandatory regression tests (production mode)

## PostgreSQL Configuration

For JIT-incompatible architectures (`test_nojit` mode), the build process automatically modifies the PostgreSQL configuration:

### Configuration Changes

The following settings are appended to `/usr/local/share/postgresql/postgresql.conf.sample`:

```
# JIT disabled for architecture compatibility (added by docker-postgis)
jit = off
```

### Benefits

- **Default Compatibility**: New PostgreSQL instances will have JIT disabled by default
- **User-Friendly**: No manual configuration required for end users
- **Documented**: Clear comment explains why JIT is disabled
- **Persistent**: Setting survives container restarts and data volume mounts

## Compiler Optimization Strategy

The workflow uses architecture-specific compiler optimization flags to balance performance and build reliability:

### Optimization Levels

| Architecture Category | Optimization Flags | Reasoning |
|----------------------|-------------------|-----------|
| **Production** (amd64, arm64) | `-O3 -mtune=generic` | Maximum performance optimization for well-tested, stable architectures |
| **Experimental** (all others) | `-O1` | Conservative optimization for faster builds and better compiler stability |

### Benefits by Category

#### Production Architectures (💻 amd64, 💪 arm64)
- **Maximum Performance**: `-O3` enables aggressive optimizations
- **Generic Tuning**: `-mtune=generic` ensures compatibility across CPU variants
- **Production Ready**: Extensively tested optimization level
- **Critical Use Cases**: Optimized for performance-sensitive deployments

#### Experimental Architectures (🦾 armv6, 🤖 armv7, 🖥️ 386, 🎯 mips64le, ⚡ ppc64le, 🧩 riscv64, 🏢 s390x)
- **Faster Builds**: `-O1` significantly reduces compilation time
- **Compiler Stability**: Lower chance of encountering optimization-related bugs
- **Development Focus**: Prioritizes build success over maximum performance
- **Debugging Friendly**: Easier to debug issues when they occur

### Technical Implementation

The optimization flags are automatically applied via the `PGIS1_OPTIMIZATION_FLAGS` build argument:

```dockerfile
ARG PGIS1_OPTIMIZATION_FLAGS=" -O3 -mtune=generic "
# Applied during PostGIS configure step:
./configure --with-optimization-flags="${PGIS1_OPTIMIZATION_FLAGS}"
```

The workflow dynamically selects the appropriate flags based on the target architecture through the `ARCH_OPTIMIZATION_FLAGS` mapping.

## Build Summary Report

The workflow generates a comprehensive summary report in the GitHub Actions interface, including a detailed regression test results table.

### Regression Test Results Table

The summary includes a table showing the status of regression tests for each architecture and image combination:

| Column | Description | Example Values |
|--------|-------------|----------------|
| **Image** | Directory being built | `17-3.5/alpine3.22` |
| **Architecture** | Target architecture with emoji | `💻 amd64`, `🧩 riscv64` |
| **Test Mode** | Regression testing mode with emoji | `🔒 require`, `🔍🐢 test_nojit` |
| **Build Type** | Native vs emulated execution | `⚡ native`, `🔄 qemu` |
| **Result** | Test outcome status | See status table below |

### Result Status Values

| Status | Emoji | Meaning | When Used |
|--------|-------|---------|-----------|
| `⏭️ Skipped` | ⏭️ | Tests were skipped | `skip` mode |
| `✅ Passed (Required)` | ✅ | Required tests passed | `require` mode success |
| `🔍✅ Completed (Tests Passed)` | 🔍✅ | Standard tests passed | `test` mode success |
| `🔍🐢✅ Completed (No-JIT Tests Passed)` | 🔍🐢✅ | No-JIT tests passed | `test_nojit` mode success |
| `❌ Failed (Build Stopped)` | ❌ | Required tests failed | `require` mode failure |
| `⚠️ Build Failed` | ⚠️ | Build error occurred | Non-require mode failures |
| `⏸️ {status}` | ⏸️ | Other status | Cancelled, skipped, etc. |

### Detailed Job Log Analysis

The workflow now includes comprehensive job log analysis that examines complete build logs (not just regression test logs) to provide detailed insights:

#### Log Analysis Features

| Feature | Description | Implementation |
|---------|-------------|----------------|
| **Error Counting** | Counts critical error patterns in complete job logs (excluding false positives) | Pattern matching for: `FATAL`, `CRITICAL`, `make: *** Error`, `ERROR.*failed`, `FAILED.*error`, `Build failed`, `compilation.*failed`, `configure.*failed`, `Connection.*failed`, `server.*terminated abnormally`. Excludes: gcc compiler flags (`-Werror`, `-Wall`, `-Wno-*`), echo statements (`echo.*ERROR`), Docker RUN commands (`RUN set.*ERROR`) |
| **Warning Counting** | Counts critical warning patterns in complete job logs (excluding documentation/build tool warnings) | Pattern matching for: `WARNING`, `WARN` (excluding disabled warnings), `deprecated`, `caution`. Excludes: git hints (`hint:`), initdb authentication warnings (`initdb:.*warning.*trust`), documentation tool warnings (`configure:.*WARNING.*not installed`, `configure:.*WARNING.*cannot be built`, `configure:.*WARNING.*stylesheets`) |
| **Test Result Analysis** | Determines specific test outcomes from log content | Analyzes regression test patterns and job conclusions |
| **Direct Log Access** | Provides clickable links to complete job logs | GitHub Actions job log URLs for detailed debugging |

#### Enhanced Test Result Status

The detailed analysis provides more granular test result status with sophisticated failure type detection:

| Status | Emoji | Meaning | Detection Logic |
|--------|-------|---------|--------------| 
| `🔍✅ Tests Passed` | 🔍✅ | Tests completed successfully | Job success + regression test pass patterns or completion messages |
| `🔍🐢✅ Tests Passed (No-JIT)` | 🔍🐢✅ | No-JIT tests completed successfully | Job success + test_nojit mode patterns + JIT disabled |
| `🔍💥 Tests Crashed (Non-blocking)` | 🔍💥 | Test execution crashed during runtime | Job success + `make: *** Error ... check-regress`, `psql: error: connection lost`, or `server terminated abnormally` patterns |
| `🔍❌ Tests Failed (Exit: N, Non-blocking)` | 🔍❌ | Tests ran but failed with specific exit code | Job success + `REGRESSION_TESTS_FAILED_EXIT_CODE_N` pattern, extracts exit code |
| `🔍❌ Tests Error` | 🔍❌ | Test execution errors (blocking) | Job failure + test/regression failure patterns |
| `🔍❌ Build Error` | 🔍❌ | Build compilation/setup errors | Job failure + general error patterns |
| `🔍✅ Build Success` | 🔍✅ | Build successful, tests not detected | Job success without specific test patterns |
| `🔍💾 Cache/No Log Analysis` | 🔍💾 | Log unavailable or from cache | Log unavailable or too short (<100 chars), likely cached build |
| `🔍⏸️ {status}` | 🔍⏸️ | Other job status | Cancelled, skipped, in progress, etc. |
| `🔍❓ Unknown` | 🔍❓ | Status could not be determined | Log unavailable or parsing errors |

#### Detailed Analysis Table

The summary includes a comprehensive analysis table:

```markdown
### Build Results & Log Analysis

| Image Directory | Architecture | Test Mode | Build Type | Errors | Warnings | Result | Log Details |
|-----------------|--------------|-----------|------------|--------|----------|--------|-------------|
| 17-3.5/alpine3.22 | amd64 | 🔒 require | ⚡ native | 0 | 20 | 🔍✅ Tests Passed | [View Logs](link) |
| 18-3.5/bookworm | arm64 | 🔒 require | ⚡ native | 0 | 17 | 🔍✅ Tests Passed | [View Logs](link) |
| 18-3.6/alpine3.22 | armv6 | 🔍 test | 🔄 qemu | 3 | 19 | 🔍✅ Build Success | [View Logs](link) |
| 17-3.5/alpine3.22 | armv7 | 🔍 test | 🔄 qemu | 3 | 19 | 🔍💥 Tests Crashed (Non-blocking) | [View Logs](link) |
| 17-3.5/alpine3.22 | riscv64 | 🔍🐢 test_nojit | 🔄 qemu | 0 | 23 | 🔍🐢✅ Tests Passed (No-JIT) | [View Logs](link) |
| 18-3.6/alpine3.22 | 386 | 🔍 test | 🔄 qemu | 2 | 22 | 🔍❌ Tests Failed (Exit: 5, Non-blocking) | [View Logs](link) |
| 17-3.5/alpine3.22 | amd64 | 🔒 require | ⚡ native | N/A | N/A | 🔍💾 Cache/No Log Analysis | [View Logs](link) |
```

#### Enhanced Test Failure Detection

The log analysis now includes sophisticated pattern matching to accurately detect test failures:

**Test Failure Patterns Detected:**
- `REGRESSION_TESTS_FAILED_EXIT_CODE_*` - Direct regression test failure marker
- `make: *** Error * check-regress` - Make target failure during regression tests
- `psql: error: connection to server was lost` - Database connection failures during tests
- `server terminated abnormally` - PostgreSQL server crashes during testing

**Test Success Patterns Detected:**
- `Regression test completed * mode * non-blocking` - Successful completion messages
- `test_nojit * mode` or `JIT disabled` - No-JIT test mode identification
- General build success without test failure markers

#### Benefits of Detailed Analysis

- **Complete Coverage**: Analyzes entire job logs, not just regression test outputs
- **Accurate Test Detection**: Sophisticated pattern matching for precise test failure identification
- **Error Quantification**: Provides exact counts of errors and warnings for debugging
- **Granular Status**: Distinguishes between test failures, build errors, and success states  
- **Direct Access**: Clickable links to complete job logs for detailed investigation
- **Historical Tracking**: Persistent analysis results in GitHub Actions summaries
- **Debugging Aid**: Quickly identify which jobs need attention and why
- **Multi-Directory Support**: Handles multiple image directories with proper separation

### Example Summary Table

```markdown
### Build Results & Log Analysis

| Image Directory | Architecture | Test Mode | Build Type | Errors | Warnings | Result | Log Details |
|-----------------|--------------|-----------|------------|--------|----------|--------|-------------|
| 17-3.5/alpine3.22 | amd64 | 🔒 require | ⚡ native | 0 | 20 | 🔍✅ Tests Passed | [View Logs] |
| 17-3.5/alpine3.22 | arm64 | 🔒 require | ⚡ native | 0 | 17 | 🔍✅ Tests Passed | [View Logs] |
| 17-3.5/alpine3.22 | armv6 | 🔍 test | 🔄 qemu | 3 | 19 | 🔍✅ Build Success | [View Logs] |
| 17-3.5/alpine3.22 | armv7 | 🔍 test | 🔄 qemu | 3 | 19 | 🔍💥 Tests Crashed (Non-blocking) | [View Logs] |
| 17-3.5/alpine3.22 | riscv64 | 🔍🐢 test_nojit | 🔄 qemu | 0 | 23 | 🔍🐢✅ Tests Passed (No-JIT) | [View Logs] |
| 17-3.5/alpine3.22 | s390x | 💨 skip | 🔄 qemu | N/A | N/A | 🔍💾 Cache/No Log Analysis | [View Logs] |
```

### Benefits

- **Quick Overview**: See all test results at a glance
- **Visual Clarity**: Emoji-based status indicators
- **Debugging Aid**: Easily identify which architectures need attention
- **Historical Record**: Summary persists in GitHub Actions logs
- **Comprehensive Status**: Shows both test mode and actual outcomes

## Workflow Jobs

### 🌍 Prepare Matrix
- **Purpose**: Dynamically generates the build matrix based on configuration
- **Outputs**: Build matrix, architecture list, image directories, push conditions
- **Key Logic**: 
  - Combines `IMAGE_DIRECTORIES` × `SUPPORTED_ARCHITECTURES`
  - Determines whether to push images based on branch/event
  - Uses `jq` for JSON manipulation

### 💻 Build Images (Multi-job)
- **Purpose**: Builds architecture-specific Docker images
- **Matrix Strategy**: One job per architecture × image directory combination
- **Key Steps**:
  1. **QEMU Setup**: Enables cross-platform builds
  2. **Docker Buildx**: Advanced build features
  3. **Dependency Installation**: Python tools, manifest-tool
  4. **Image Building**: Architecture-specific builds with caching and regression mode configuration
  5. **Testing**: Official PostgreSQL test suite validation
  6. **Push**: Conditional push to registry
- **Regression Testing**: Each build uses architecture-specific regression mode (`require` for production, `test` for experimental)

### 📦 Create Manifests (Multi-job)
- **Purpose**: Creates multi-architecture manifests
- **Strategy**: One job per image directory
- **Key Features**:
  - Removes existing manifests before creation
  - Properly annotates each architecture
  - Validates manifest architecture count
  - Only runs when images should be pushed

### 📊 Build Summary
- **Purpose**: Provides comprehensive build results and regression test overview
- **Features**:
  - Success/failure status for each phase
  - Detailed regression test results table
  - Architecture support summary
  - Registry configuration details
  - Always runs regardless of job failures
- **Regression Test Results Table**: Shows detailed status for each architecture and image combination

## Branch Configuration

The workflow supports configurable branch targeting:

- **Testing Mode**: Set `TARGET_BRANCH: 'manifest'`
  - Builds and pushes on `manifest` branch
  - Allows testing without affecting production

- **Production Mode**: Set `TARGET_BRANCH: 'master'`
  - Builds and pushes on `master` branch
  - Production deployment mode

## Testing Framework

### Image Testing
- Uses official PostgreSQL test suite
- Tests run natively on each architecture
- Validates PostGIS functionality
- Fails fast on test errors

### Manifest Validation
- Verifies correct architecture count
- Ensures all expected architectures are present
- Uses `EXPECTED_ARCHS` dynamic calculation

## Performance Optimizations

### Caching Strategy
- **GitHub Actions Cache**: Build cache persistence
- **Docker Layer Caching**: Faster subsequent builds
- **Conditional Builds**: Only build changed directories

### Parallel Execution
- **Matrix Jobs**: All architectures build simultaneously (max-parallel: 10) - Limited to avoid overwhelming 3rd party servers (projsync, package repositories, etc.)
- **Manifest Creation**: Sequential processing (max-parallel: 1) to avoid Docker Hub rate limiting
- **Runner Optimization**: Native ARM runners for ARM builds
- **Fail-Fast Disabled**: Continue building other architectures on failure

## Error Handling

### Build Failures
- Individual architecture failures don't stop others
- Clear error reporting in job names
- Comprehensive logging for debugging

### Manifest Creation
- Validates all required images exist before manifest creation
- Graceful handling of missing architecture images
- Detailed error messages for troubleshooting

## Security Considerations

### Secrets Management
- `DOCKERHUB_USERNAME`: Docker Hub authentication
- `DOCKERHUB_ACCESS_TOKEN`: Docker Hub access token
- Secrets only used in push operations
- No secrets exposed in logs

### Image Security
- Provenance and SBOM disabled for faster builds
- Consider enabling for production security scanning
- Regular base image updates recommended

## Maintenance

### Regular Updates
1. **Architecture Support**: Review and add new architectures as needed
2. **Runner Updates**: Keep GitHub runner versions current
3. **Tool Versions**: Update manifest-tool and other dependencies
4. **Base Images**: Regular updates via dependabot or manual process

### Monitoring
- Use GitHub Actions logs for build monitoring
- Set up notifications for build failures
- Monitor registry storage usage

## Common Issues and Solutions

### Build Failures
- **Architecture mismatch**: Check `ARCH_PLATFORMS` mapping
- **Runner unavailable**: Verify GitHub runner availability
- **Cross-compilation errors**: Review QEMU setup and build args

### Manifest Issues  
- **Missing architectures**: Ensure all builds completed successfully
- **Annotation errors**: Verify `ARCH_ANNOTATIONS` format
- **Registry permissions**: Check Docker Hub credentials

### Performance Issues
- **Slow builds**: Enable more aggressive caching
- **Runner queue times**: Consider self-hosted runners for high-volume builds
- **Registry rate limits**: Implement build throttling if needed

## Integration Points

### With Other Workflows
- Coordinates with `main.yml` for production builds
- Integrates with `tools/apply-ci.sh` for directory updates
- Uses shared configuration from repository root

### External Dependencies
- **Docker Hub**: Primary registry for image distribution  
- **GitHub Actions**: CI/CD platform
- **QEMU**: Cross-platform emulation
- **manifest-tool**: Multi-arch manifest management

## Future Enhancements

### Potential Improvements
- **Registry Mirroring**: Support multiple registries simultaneously
- **Build Optimization**: Implement more sophisticated caching
- **Security Scanning**: Integrate vulnerability scanning
- **Notification System**: Advanced build status notifications
- **Metrics Collection**: Build performance and success rate tracking

## Reusable Workflow Template System

### Template-Based Architecture

Starting with the latest implementation, the workflow system has been refactored into a reusable template system for better maintainability and flexibility:

#### Core Template

- **`build-manifest-template.yml`**: Reusable workflow template containing all build logic
- **Input Parameters**: Configurable workflow name, architectures, image directories, registry settings
- **Shared Functionality**: All build, test, manifest creation, and log analysis logic
- **Concurrency Control**: Only one instance runs at a time across all workflows (`cancel-in-progress: false`)

#### Variant-Specific Workflows

- **`manifest-alpine-8arch.yml`**: Alpine-based builds with full architecture support
  - Architectures: `["amd64", "arm64", "armv6", "armv7", "386", "ppc64le", "riscv64", "s390x"]` (8 architectures)
  - Image Directories: `["13-3.5/alpine3.22", "14-3.5/alpine3.22", "15-3.5/alpine3.22", "16-3.5/alpine3.22", "17-3.5/alpine3.22", "18-3.5/alpine3.22"]`
  - Execution: Auto-queued by template concurrency

- **`manifest-alpine-2arch.yml`**: Alpine-based builds with production architectures
  - Architectures: `["amd64", "arm64"]` (2 production architectures)
  - Image Directories: Alpine 3.22 (3.4, 3.6 versions) + Alpine 3.21 (all 3.3, 3.4, 3.5 versions) - 21 directories total
  - Execution: Auto-queued by template concurrency

- **`manifest-bookworm.yml`**: Bookworm-based builds with production architectures
  - Architectures: `["amd64", "arm64"]` (production architectures only)
  - Image Directories: `["13-3.5/bookworm", "14-3.5/bookworm", "15-3.5/bookworm", "18-3.5/bookworm"]` (16-3.5, 17-3.5 moved to Bundle0)
  - Execution: Auto-queued by template concurrency

- **`manifest-bullseye.yml`**: Bullseye-based builds with production architectures
  - Architectures: `["amd64", "arm64"]` (production architectures only)
  - Image Directories: `["13-3.5/bullseye", "14-3.5/bullseye", "15-3.5/bullseye", "16-3.5/bullseye", "17-3.5/bullseye"]`
  - Execution: Auto-queued by template concurrency

- **`manifest-recent.yml`**: Recent Debian builds with production architectures
  - Architectures: `["amd64", "arm64"]` (production architectures only)
  - Image Directories: `["16-recent/bookworm", "17-recent/bookworm", "18-recent/bookworm"]`
  - Execution: Auto-queued by template concurrency

- **`manifest-master.yml`**: Master Debian builds with production architectures
  - Architectures: `["amd64", "arm64"]` (production architectures only)
  - Image Directories: `["16-master/bookworm", "17-master/bookworm", "18-master/bookworm"]`
  - Execution: Auto-queued by template concurrency

- **`manifest-locked.yml`**: Locked version builds for specific use cases
  - Architectures: `["amd64"]` (single architecture only)
  - Image Directories: `["14-l3.1.9gcp/bookworm"]`
  - Execution: Auto-queued by template concurrency

- **`manifest-bundle0.yml`**: Two-step Bundle0 builds (self-contained with dependencies)
  - Architectures: `["amd64", "arm64"]` (production architectures)
  - **Step 1**: Base images `["16-3.5/bookworm", "17-3.5/bookworm"]` (moved from manifest-bookworm.yml)
  - **Step 2**: Bundle0 images `["16-3.5-bundle0/bookworm", "17-3.5-bundle0/bookworm"]` (needs Step 1)
  - Execution: Auto-queued by template concurrency with explicit `needs` dependency between steps
  - Self-contained: No external dependencies on other workflows


#### Benefits of Template System

1. **Code Reuse**: Single source of truth for build logic
2. **Consistent Behavior**: All variants use identical build processes
3. **Easy Maintenance**: Updates to core logic apply to all variants
4. **Flexible Configuration**: Each variant can have different architectures and directories
5. **Scalable**: Easy to add new variants (Ubuntu, Rocky Linux, etc.)
6. **Execution Control**: Choose parallel or sequential execution based on needs
7. **Concurrency Protection**: Template runs only one instance at a time, preventing resource conflicts

#### Execution Model

**Auto-Queued Execution** (All variant workflows):
- **Template Concurrency**: Only one template instance runs at a time
- **Automatic Queuing**: Multiple workflow triggers are automatically queued
- **Independent Triggers**: Each variant can be triggered independently
- **Sequential Execution**: Despite parallel triggers, runs execute sequentially due to concurrency control
- **Simplified Management**: No need for explicit `needs` dependencies between variants

#### Usage Pattern

**Template Usage** (All variants follow this pattern):
```yaml
jobs:
  build-variant:
    uses: ./.github/workflows/build-manifest-template.yml
    with:
      workflow_name: "Alpine-8Arch"  # or "Alpine-2Arch", "Bookworm", "Bullseye", "Recent", "Master", "Locked", "Bundle0"
      supported_architectures: '["amd64", "arm64"]'
      image_directories: '["17-3.5/alpine3.22"]'
      target_branch: "manifest"
      registry: "docker.io"
      repo_name: "imresamu"
      image_name: "postgistest"
    secrets:
      DOCKERHUB_USERNAME: ${{ secrets.DOCKERHUB_USERNAME }}
      DOCKERHUB_ACCESS_TOKEN: ${{ secrets.DOCKERHUB_ACCESS_TOKEN }}
```

**Automatic Concurrency Control**:
- Template ensures only one instance runs at a time
- No manual `needs` dependencies required for concurrency control
- Workflows can be triggered independently
- Execution order determined by trigger timing and queue
- **Note**: Some workflows have logical dependencies (e.g., Bundle0 depends on Bookworm base images), but concurrency control is still automatic

#### Migration Path

- **Current**: `test_manifest.yml` remains as the original comprehensive workflow
- **Future**: New variants use the template system for consistency
- **Flexibility**: Can gradually migrate existing workflows to use templates

This template-based approach provides a production-ready multi-architecture Docker build system with excellent maintainability, extensibility, and configuration flexibility.