# Multi-Architecture Docker Build Template

This document describes the `template-workflow-multiarch.yml` GitHub Actions workflow template, which provides a reusable system for building and testing multi-architecture Docker images for PostGIS containers.

## Overview

The workflow template implements a sophisticated multi-architecture Docker build system that:
- Builds Docker images for multiple CPU architectures (amd64, arm64, etc.)
- Creates multi-architecture manifests efficiently with reduced API calls
- Provides comprehensive testing and validation
- Uses emoji-based job naming for improved UI readability
- Serves as a reusable template for different build groups

## Architecture Support

The workflow template supports these architectures with their corresponding configuration:

| Architecture | Emoji | Runner | Platform | Regression Mode | Build Type | Optimization | LTO | Use Case |
|--------------|-------|--------|----------|-----------------|------------|--------------|-----|----------|
| **amd64** | 💻 | ubuntu-24.04 | linux/amd64 | require 🔒 | native ⚡ | -O3 -Wall -fno-omit-frame-pointer | --enable-lto | Intel/AMD 64-bit (Production) |
| **arm64** | 💪 | ubuntu-24.04-arm | linux/arm64 | require 🔒 | native ⚡ | -O3 -Wall -fno-omit-frame-pointer | --enable-lto | Apple Silicon, AWS Graviton (Production) |
| **armv6** | 🦾 | ubuntu-24.04-arm | linux/arm/v6 | test_nojit 🔍🐢 | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer | - | Raspberry Pi Zero (JIT-incompatible) |
| **armv7** | 🤖 | ubuntu-24.04-arm | linux/arm/v7 | test_nojit 🔍🐢 | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer | - | Raspberry Pi 2/3/4 (JIT-incompatible) |
| **386** | 🖥️ | ubuntu-24.04 | linux/386 | test 🔍 | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer | - | Legacy 32-bit Intel (Experimental) |
| **mips64le** | 🎯 | ubuntu-24.04 | linux/mips64le | skip_nojit 💨🐢 | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer | - | MIPS 64-bit systems (Skip Tests + No JIT) |
| **ppc64le** | ⚡ | ubuntu-24.04 | linux/ppc64le | test_nojit 🔍🐢 | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer | - | IBM POWER systems (No-JIT) |
| **riscv64** | 🧩 | ubuntu-24.04 | linux/riscv64 | test_nojit 🔍🐢 | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer | - | RISC-V 64-bit (No-JIT) |
| **s390x** | 🏢 | ubuntu-24.04 | linux/s390x | skip_nojit 💨🐢 | qemu 🔄 | -O1 -Wall -fno-omit-frame-pointer | - | IBM mainframes (Skip Tests + No JIT) |

## Template System

### Core Template Structure

The `template-workflow-multiarch.yml` serves as a reusable workflow template that accepts input parameters to configure builds for different scenarios:

#### Input Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `workflow_name` | Yes | - | Name of the workflow (e.g., "Alpine", "Debian") |
| `supported_architectures` | Yes | - | JSON array of architectures to build |
| `image_directories` | Yes | - | JSON array of image directories to build |
| `target_branch` | No | `manifest` | Branch for automated builds |
| `registry` | No | `docker.io` | Docker registry URL |
| `repo_name` | No | `imresamu` | Repository name |
| `image_name` | No | `postgistest` | Base image name |
| `schedule_parallel` | No | `8` | Max parallel builds for scheduled runs |
| `manual_parallel` | No | `6` | Max parallel builds for manual runs |
| `push_pr_parallel` | No | `4` | Max parallel builds for push/PR runs |

#### Required Secrets

- `DOCKERHUB_USERNAME`: Docker Hub authentication username
- `DOCKERHUB_ACCESS_TOKEN`: Docker Hub access token

### Usage Example

```yaml
jobs:
  build-bookworm:
    uses: ./.github/workflows/template-workflow-multiarch.yml
    with:
      workflow_name: "Bookworm"
      supported_architectures: '["amd64", "arm64"]'
      image_directories: '["17-3.5/bookworm", "18-3.5/bookworm"]'
      target_branch: "manifest"
      registry: "docker.io"
      repo_name: "imresamu"
      image_name: "postgistest"
      schedule_parallel: 6
      manual_parallel: 4
      push_pr_parallel: 2
    secrets:
      DOCKERHUB_USERNAME: ${{ secrets.DOCKERHUB_USERNAME }}
      DOCKERHUB_ACCESS_TOKEN: ${{ secrets.DOCKERHUB_ACCESS_TOKEN }}
```

## Regression Testing Modes

The workflow supports five regression testing modes for PostGIS builds:

### Mode Descriptions

| Mode | Emoji | Description | Behavior | JIT Setting | Use Case |
|------|-------|-------------|----------|-------------|----------|
| `skip` | 💨 | No regression tests | Tests are completely skipped | N/A | Fast builds, debugging |
| `skip_nojit` | 💨🐢 | No regression tests + JIT disabled | Tests are skipped but JIT disabled for end users | Disabled + Config Modified | Problematic architectures needing JIT disabled |
| `test` | 🔍 | Non-blocking tests | Tests run but failures don't fail the build | Enabled | Development, experimental architectures |
| `test_nojit` | 🔍🐢 | Non-blocking tests without JIT | Tests run with JIT disabled, failures don't fail build | Disabled + Config Modified | JIT-incompatible architectures |
| `require` | 🔒 | Blocking tests | Tests must pass or build fails | Enabled | Production architectures |

### Architecture-Specific Test Configuration

- **Production Architectures** (amd64, arm64): Use `require` mode
  - Tests must pass for build to succeed
  - Native execution with JIT enabled
  - Maximum performance optimization (-O3)

- **Experimental Architectures** (386): Use `test` mode  
  - Tests run but build continues on failure
  - QEMU emulation with conservative optimization (-O1)

- **JIT-Incompatible Architectures** (armv6, armv7, riscv64, ppc64le): Use `test_nojit` mode
  - Tests run with JIT disabled for compatibility
  - PostgreSQL configuration modified to disable JIT by default
  - ARM v6/v7 architectures often have JIT stability issues
  - PPC64LE and RISC-V architectures have JIT compatibility issues

- **Problematic Architectures** (mips64le, s390x): Use `skip_nojit` mode
  - No regression tests for fastest builds (QEMU emulation issues)
  - PostgreSQL configuration modified to disable JIT by default for end users
  - Focus on successful compilation with JIT disabled

## Compiler Optimization Strategy

The workflow uses architecture-specific compiler optimization flags to balance performance and build reliability:

### Optimization Levels

| Architecture Category | Flags | LTO | Reasoning |
|----------------------|-------|-----|-----------|
| **Production** (amd64, arm64) | `-O3 -Wall -fno-omit-frame-pointer` | `--enable-lto` | Maximum performance optimization for stable architectures |
| **Experimental** (all others) | `-O1 -Wall -fno-omit-frame-pointer` | - | Conservative optimization for build stability |

## Manifest Creation Optimization

The template uses `docker buildx imagetools create` for efficient multi-architecture manifest creation with **significant improvements** over traditional approaches:

### Key Improvements

- **Single API call per manifest** instead of multiple `docker manifest` commands
- **Automatic platform detection** from source images  
- **75% reduction in Docker Hub API calls** compared to traditional approach
- **Sequential processing** in single job instead of matrix approach for better debugging
- **No JSON parsing errors** - `docker buildx imagetools inspect` provides clean output
- **Faster execution** - eliminates annotation loops and redundant API calls

### Traditional vs Optimized Approach

```bash
# Traditional (6+ API calls per manifest)
docker manifest rm target                                     # 1 API call
docker manifest create target source1 source2                # 1 API call  
docker manifest annotate target source1 --os linux --arch amd64  # 1 API call
docker manifest annotate target source2 --os linux --arch arm64  # 1 API call
docker manifest push target                                   # 1 API call
docker manifest inspect target | jq '.manifests | length'    # 1 API call + JSON parsing

# Optimized (2 API calls per manifest)  
docker buildx imagetools create -t target source1 source2    # 1 API call
docker buildx imagetools inspect target                       # 1 API call
```

### Manifest Processing Approach

**Previous Matrix Approach (Problematic):**
- Each image directory processed in separate job
- Parallel manifest creation causing resource contention
- Complex job dependencies and potential race conditions
- Scattered logs across multiple jobs

**Current Sequential Approach (Optimized):**
- All image directories processed in single job
- Sequential manifest creation with clear progress logging
- Consolidated debug output with `set -x`
- Single job failure point for easier troubleshooting

### Real-World Performance

Based on typical Debian workflow execution:
- **13 manifests created** in ~10 seconds total
- **26 total API calls** (2 per manifest) vs **78+ traditional API calls**
- **No rate limiting issues** observed
- **Clean execution logs** without JSON parsing errors

## Job Structure

### 1. Prepare Matrix Job
- **Purpose**: Generates build matrix dynamically
- **Outputs**: Build matrix, architecture list, image directories, push conditions
- **Key Logic**: Combines image directories × supported architectures

### 2. Build Images Job (Matrix)
- **Purpose**: Builds architecture-specific Docker images
- **Matrix Strategy**: One job per architecture × image directory combination
- **Key Steps**:
  1. QEMU setup for cross-platform builds (QEMU architectures only)
  2. Docker Buildx configuration with explicit platform
  3. Dependency installation
  4. Image building with architecture-specific build arguments
  5. Official test suite validation
  6. Conditional push to registry

### 3. Create Manifests Job (Single)
- **Purpose**: Creates multi-architecture manifests for all images
- **Strategy**: Sequential processing of all image directories
- **Key Features**:
  - Processes all image directories in single job
  - Uses optimized `docker buildx imagetools create`
  - Validates manifest architecture count
  - Debug-friendly logging with `set -x`

## Build Arguments Integration

The template automatically passes these build arguments to Dockerfiles:

### Standard Arguments
- `PGIS1_REGRESSION_MODE`: Controls regression test behavior (skip, skip_nojit, test, test_nojit, require)
- `PGIS1_OPTIMIZATION_FLAGS`: Compiler optimization level (-O1 or -O3 with architecture-specific flags)
- `PGIS1_LTO_FLAGS`: Link-time optimization settings (enabled for production architectures)
- `BUILD_DATE`: Build timestamp for Docker labels (e.g., `2025-07-02T16:19:44+02:00`)

### Registry Arguments (for Bundle Images)
- `REGISTRY`: Docker registry URL (e.g., `docker.io`) - only populated for bundle builds
- `REPO_NAME`: Repository name (e.g., `imresamu`) - only populated for bundle builds  
- `IMAGE_NAME`: Base image name with architecture suffix (e.g., `postgistest-amd64`)

These arguments enable bundle images to reference the correct base images across architectures and ensure proper Docker label timestamps.

## Job Naming Convention

The workflow uses descriptive emoji-based job names:

**Format**: `{arch_emoji}{arch_name}|{regression_emoji}{image_dir}{build_type_emoji}`

**Examples**:
- `💻amd64|🔒17-3.5/bookworm⚡` - Native amd64, required tests
- `🧩riscv64|🔍🐢17-3.5/alpine3.22🔄` - QEMU riscv64, no-JIT tests
- `🏢s390x|💨🐢17-3.5/alpine3.22🔄` - QEMU s390x, skip tests + no JIT
- `🎯mips64le|💨🐢16-3.5/bookworm🔄` - QEMU mips64le, skip tests + no JIT

## Performance Optimizations

### Build Optimizations
- **GitHub Actions Cache**: Persistent build cache with architecture-specific scoping
- **Docker Layer Caching**: Faster subsequent builds with zstd compression
- **Native ARM Runners**: Direct ARM64 execution without emulation
- **QEMU Only When Needed**: Conditional QEMU setup based on build type

### Dynamic Parallel Execution

The template supports **context-aware parallel execution** that adapts based on how the workflow is triggered:

#### Parallel Build Configuration

Each workflow can define custom parallel limits for different trigger scenarios:

| Trigger Type | Parameter | Default | Description |
|--------------|-----------|---------|-------------|
| **Scheduled** | `schedule_parallel` | 8 | Only 1 workflow runs, higher parallelism allowed |
| **Manual** | `manual_parallel` | 6 | 1-2 workflows typically run, moderate parallelism |
| **Push/PR** | `push_pr_parallel` | 4 | 2-3 workflows may run simultaneously, conservative parallelism |

#### Dynamic Logic

```yaml
max-parallel: ${{ github.event_name == 'schedule' && inputs.schedule_parallel || github.event_name == 'workflow_dispatch' && inputs.manual_parallel || inputs.push_pr_parallel }}
```

#### Workflow-Specific Examples

**Alpine Workflow (8 architectures):**
```yaml
schedule_parallel: 8    # Full parallelism when alone
manual_parallel: 6      # Moderate when potentially concurrent  
push_pr_parallel: 4     # Conservative when multiple workflows active
```

**Debian Workflow (2 architectures):**
```yaml
schedule_parallel: 6    # Higher than arch count for image parallelism
manual_parallel: 4      # Moderate parallelism
push_pr_parallel: 2     # Match architecture count
```

#### Resource Management Benefits

- **Scheduled Runs**: Maximum throughput (only 1 workflow active)
- **Manual Runs**: Balanced performance and resource usage
- **Push/PR Events**: Prevents resource contention when multiple workflows trigger
- **Flexible Configuration**: Each workflow optimizes based on its architecture count and complexity

### Traditional Parallel Execution
- **Fail-Fast Disabled**: Continue building other architectures on failure
- **Sequential Manifests**: Single job processes all manifests for better debugging

### Registry Efficiency
- **Reduced API Calls**: 75% fewer Docker Hub API calls
- **Conditional Push**: Only push when appropriate branch/event
- **Efficient Manifest Creation**: Single job instead of matrix

## Error Handling

### Build Failures
- Individual architecture failures don't stop others
- Clear error reporting in emoji-based job names
- Comprehensive logging for debugging

### Manifest Creation
- Validates all required images exist before manifest creation
- Sequential processing prevents race conditions
- Detailed error messages for troubleshooting

## Security Considerations

### Secrets Management
- Secrets only used in push operations
- No secrets exposed in logs
- Conditional credential checking

### Image Security
- Provenance and SBOM disabled for faster builds
- Regular base image updates recommended
- Architecture-specific security scanning possible

## Adding New Architectures

To add support for new architectures in the template:

1. **Update environment variables** in the template:
   ```yaml
   ARCH_RUNNERS: '{"new_arch": "ubuntu-24.04"}'
   ARCH_PLATFORMS: '{"new_arch": "linux/new_arch"}'
   ARCH_EMOJIS: '{"new_arch": "🔥"}'
   ARCH_REGRESSION_MODES: '{"new_arch": "test"}'
   # ... other mappings
   ```

2. **Include in caller workflow**:
   ```yaml
   supported_architectures: '["amd64", "arm64", "new_arch"]'
   ```

3. **No code changes required** - the template dynamically generates the build matrix

## Common Issues and Solutions

### Build Failures
- **Architecture mismatch**: Check environment variable mappings
- **Runner unavailable**: Verify GitHub runner availability  
- **Cross-compilation errors**: Review QEMU setup and build args

### Manifest Issues
- **Missing architectures**: Ensure all builds completed successfully
- **API rate limits**: Template optimization should prevent this
- **Registry permissions**: Check Docker Hub credentials

### Template Usage
- **Parameter validation**: Ensure all required inputs are provided
- **JSON formatting**: Verify array parameters use proper JSON format
- **Secret access**: Ensure calling workflow has access to required secrets

## Integration with Build Workflows

### Current Build Workflows

#### `workflow-build-debian.yml` - Debian Build Group (Active)
**Schedule**: Monday 02:00 UTC (`cron: '0 2 * * 1'`)

The Debian workflow has been optimized into **3 sequential steps** with **priority-based execution** and **descending PostgreSQL version order**:

| Step | Name | Dependencies | PostgreSQL Versions | Directories | Purpose |
|------|------|--------------|-------------------|-------------|---------|
| **1** | `Bookworm [1/3]` | None | 18 → 17 → 16 → 15 → 14 → 13 | 6 directories | **Base images** - highest priority |
| **2** | `Bullseye [2/3]` | Needs: bookworm | 17 → 16 → 15 → 14 → 13 | 5 directories | **Alternative base** - medium priority |
| **3** | `Bundle0 [3/3]` | Needs: bullseye | 17 → 16 | 2 directories | **Extended bundles** - lowest priority |

**Key Features:**
- **Priority Execution**: Base images built first, bundles last
- **Descending Version Order**: Latest PostgreSQL versions processed first (18 → 13)
- **Progress Indicators**: `[1/3]`, `[2/3]`, `[3/3]` show completion status
- **Dependency Chain**: `bookworm` → `bullseye` → `bundle0` ensures proper build order
- **Consolidated Steps**: Reduced from 4 jobs to 3 jobs for better resource utilization

**Image Directories by Step:**
```yaml
# Step 1: Bookworm [1/3] (Base Images - Highest Priority)
image_directories: [
  "18-3.5/bookworm",   # PostgreSQL 18 (latest)
  "17-3.5/bookworm",   # PostgreSQL 17
  "16-3.5/bookworm",   # PostgreSQL 16  
  "15-3.5/bookworm",   # PostgreSQL 15
  "14-3.5/bookworm",   # PostgreSQL 14
  "13-3.5/bookworm"    # PostgreSQL 13 (oldest)
]

# Step 2: Bullseye [2/3] (Alternative Base - Medium Priority)
image_directories: [
  "17-3.5/bullseye",   # PostgreSQL 17
  "16-3.5/bullseye",   # PostgreSQL 16
  "15-3.5/bullseye",   # PostgreSQL 15
  "14-3.5/bullseye",   # PostgreSQL 14
  "13-3.5/bullseye"    # PostgreSQL 13
]

# Step 3: Bundle0 [3/3] (Extended Bundles - Lowest Priority)
image_directories: [
  "17-3.5-bundle0/bookworm",  # PostgreSQL 17 + Bundle
  "16-3.5-bundle0/bookworm"   # PostgreSQL 16 + Bundle
]
```

#### `workflow-build-alpine.yml` - Alpine Build Group (Active)
- **Status**: Active multi-architecture Alpine builds (7 architectures - s390x temporarily removed)
- **Schedule**: Tuesday 02:00 UTC (`cron: '0 2 * * 2'`)
- **Architecture Count**: 7 (amd64, arm64, armv6, armv7, 386, ppc64le, riscv64)

#### `workflow-build-development.yml` - Development Build Group (Active)  
- **Status**: Active development builds (Master/Recent/Locked)
- **Schedule**: Wednesday 02:00 UTC (`cron: '0 2 * * 3'`)

### Migration Path
- Existing workflows can gradually migrate to use the template
- Template provides consistent behavior across all build types
- Easy to add new build groups using the template

## Future Enhancements

### Potential Improvements
- **Registry Mirroring**: Support multiple registries simultaneously
- **Advanced Caching**: More sophisticated build cache strategies
- **Security Scanning**: Integrate vulnerability scanning
- **Build Metrics**: Performance and success rate tracking
- **Summary Reports**: Enhanced build result reporting (currently disabled)

## Template Benefits

### Code Reuse
- Single source of truth for build logic
- Consistent behavior across all variants
- Easy maintenance and updates

### Flexibility
- Configurable architectures per build workflow
- Customizable registry settings
- Branch-specific targeting
- **Dynamic parallel execution** based on trigger type
- **Per-workflow resource optimization**

### Scalability  
- Easy to add new build workflows
- Template handles complexity automatically
- Resource protection with parallel limits

## Template Usage in Practice

The `template-workflow-multiarch.yml` is currently used by these active workflows:

### Current Parallel Configuration

| Workflow | Trigger | Schedule | Manual | Push/PR | Architecture Count |
|----------|---------|----------|--------|---------|--------------------|
| **`workflow-build-debian.yml`** | Monday 02:00 UTC | 6 | 4 | 2 | 2 architectures (3 steps) |
| **`workflow-build-alpine.yml`** | Tuesday 02:00 UTC | 8 | 6 | 4 | 7 architectures (6 steps) - s390x removed |
| **`workflow-build-development.yml`** | Wednesday 02:00 UTC | 4 | 3 | 2 | 2+1 architectures (3 steps) |

### Resource Utilization by Scenario

**Scheduled Runs (Weekdays 02:00 UTC):**
- Only 1 workflow active per day (priority: Debian → Alpine → Development)
- Maximum parallelism: Debian=6, Alpine=8, Development=4
- **Total resource usage**: 4-8 parallel builds (Alpine reduced from 8 to 7 architectures)

**Manual Triggers:**
- 1-2 workflows typically active
- Moderate parallelism: Debian=4, Alpine=6, Development=3  
- **Total resource usage**: 3-9 parallel builds (Alpine architecture reduction)

**Push/PR Events:**
- 2-3 workflows may trigger simultaneously
- Conservative parallelism: Debian=2, Alpine=4, Development=2
- **Total resource usage**: 2-8 parallel builds (resource-safe, Alpine s390x removal improves stability)

This template-based approach provides a production-ready, maintainable, and efficient multi-architecture Docker build system optimized for reduced API usage and improved debugging capabilities.