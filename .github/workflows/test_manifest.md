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
| amd64        | linux/amd64     | ubuntu-24.04 | 💻 | require | native ⚡ | -O3 -mtune=generic | Intel/AMD 64-bit (Production) |
| arm64        | linux/arm64     | ubuntu-24.04-arm | 💪 | require | native ⚡ | -O3 -mtune=generic | Apple Silicon, AWS Graviton (Production) |
| armv6        | linux/arm/v6    | ubuntu-24.04-arm | 🦾 | test | qemu 🔄 | -O1 | Raspberry Pi Zero (Experimental) |
| armv7        | linux/arm/v7    | ubuntu-24.04-arm | 🤖 | test | qemu 🔄 | -O1 | Raspberry Pi 2/3/4 (Experimental) |
| 386          | linux/386       | ubuntu-24.04 | 🖥️ | test | qemu 🔄 | -O1 | Legacy 32-bit Intel (Experimental) |
| mips64le     | linux/mips64le  | ubuntu-24.04 | 🎯 | test_nojit | qemu 🔄 | -O1 | MIPS 64-bit systems (No-JIT) |
| ppc64le      | linux/ppc64le   | ubuntu-24.04 | ⚡ | test | qemu 🔄 | -O1 | IBM POWER systems (Experimental) |
| riscv64      | linux/riscv64   | ubuntu-24.04 | 🧩 | test_nojit | qemu 🔄 | -O1 | RISC-V 64-bit (No-JIT) |
| s390x        | linux/s390x     | ubuntu-24.04 | 🏢 | test_nojit | qemu 🔄 | -O1 | IBM mainframes (No-JIT) |

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

- **JIT-Incompatible Architectures** (`mips64le`, `riscv64`, `s390x`): Use `test_nojit` mode
  - Tests run with JIT disabled for compatibility
  - Build continues even if tests fail
  - Server restart ensures clean state after potentially failed regression tests
  - Extension testing performed with JIT disabled
  - PostgreSQL configuration modified to disable JIT by default for end users
  - Regression logs saved compressed for debugging

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
| `🔍 Completed (Non-blocking)` | 🔍 | Standard tests completed | `test` mode (any outcome) |
| `🔍🐢 Completed (No-JIT, Non-blocking)` | 🔍🐢 | No-JIT tests completed | `test_nojit` mode (any outcome) |
| `❌ Failed (Build Stopped)` | ❌ | Required tests failed | `require` mode failure |
| `⚠️ Build Failed` | ⚠️ | Build error occurred | Non-require mode failures |
| `⏸️ {status}` | ⏸️ | Other status | Cancelled, skipped, etc. |

### Example Summary Table

```markdown
### Regression Test Results

| Image | Architecture | Test Mode | Build Type | Result |
|-------|--------------|-----------|------------|--------|
| 17-3.5/alpine3.22 | 💻 amd64 | 🔒 require | ⚡ native | ✅ Passed (Required) |
| 17-3.5/alpine3.22 | 💪 arm64 | 🔒 require | ⚡ native | ✅ Passed (Required) |
| 17-3.5/alpine3.22 | 🦾 armv6 | 🔍 test | 🔄 qemu | 🔍 Completed (Non-blocking) |
| 17-3.5/alpine3.22 | 🧩 riscv64 | 🔍🐢 test_nojit | 🔄 qemu | 🔍🐢 Completed (No-JIT, Non-blocking) |
| 17-3.5/alpine3.22 | 🎯 mips64le | 🔍🐢 test_nojit | 🔄 qemu | 🔍🐢 Completed (No-JIT, Non-blocking) |
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
- **Matrix Jobs**: All architectures build simultaneously
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

This workflow represents a production-ready multi-architecture Docker build system with excellent maintainability and extensibility.