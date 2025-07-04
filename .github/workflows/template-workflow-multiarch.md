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
| `workflow_cache_id` | Yes | - | Unique 3-character workflow cache identifier (alp, deb, dev) |
| `cache_registry` | No | `ghcr.io` | Cache registry URL |
| `cache_repo_owner` | No | `{repo_name}` | Cache repository owner (automatically derived from repo_name) |
| `cache_image_name` | No | `{image_name}-cache` | Cache image base name (automatically derived from image_name) |

#### Required Secrets

- `DOCKERHUB_USERNAME`: Docker Hub authentication username
- `DOCKERHUB_ACCESS_TOKEN`: Docker Hub access token

#### Required Permissions

The template requires specific GitHub Actions permissions for proper operation:

```yaml
permissions:
  actions: write     # Required for workflow re-run functionality
  contents: read     # Required for repository access
  packages: write    # Required for GHCR cache write access
```

**Critical**: The `packages: write` permission is essential for Docker build cache functionality. Without it, cache writes to GitHub Container Registry (GHCR) will fail, causing cache-related build errors.

#### Concurrency Control (Recommended)

All calling workflows should include concurrency control to prevent resource conflicts:

```yaml
concurrency:
  group: "workflow-specific-builds"  # Use unique group name per workflow
  cancel-in-progress: false          # Queue builds instead of canceling
```

**Benefits:**
- **Sequential execution**: Only one build runs at a time per workflow type
- **Resource protection**: Prevents GitHub Actions resource exhaustion
- **Build integrity**: Avoids cache conflicts between simultaneous builds
- **Queue management**: Builds wait in queue rather than being canceled

### Usage Example

```yaml
permissions:
  actions: write
  contents: read
  packages: write

concurrency:
  group: "debian-builds"
  cancel-in-progress: false

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
      workflow_cache_id: "deb"
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
  5. Official test suite validation with PostgreSQL timeout configuration
  6. Conditional push to registry

#### PostgreSQL Test Configuration
The template includes specific timeout configuration for the official PostgreSQL test suite:

- **POSTGRES_TEST_TRIES**: `60` - Maximum retry attempts for PostgreSQL connection tests
- **POSTGRES_TEST_SLEEP**: `2` - Sleep seconds between retry attempts  
- **Maximum timeout**: 120 seconds (60 × 2 seconds)

These variables are used by the [docker-library/official-images test framework](https://github.com/docker-library/official-images/blob/master/test/tests/postgres-basics/run.sh):
```bash
retry.sh --tries "$POSTGRES_TEST_TRIES" --sleep "$POSTGRES_TEST_SLEEP" "echo 'SELECT 1' | psql"
```

**Rationale**: QEMU emulated architectures require more time for PostgreSQL to start and respond, but native builds also benefit from the generous timeout to prevent intermittent test failures.

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
  - **Alpine/Master templates**: Controls actual PostGIS regression testing during build
  - **Debian template**: Stored in labels only (Debian uses pre-compiled packages)
  - **Bundle template**: Inherited from base image, stored in labels
- `PGIS1_OPTIMIZATION_FLAGS`: Compiler optimization level (-O1 or -O3 with architecture-specific flags)
  - **Alpine/Master templates**: Used for PostGIS compilation from source (`CFLAGS="${PGIS1_OPTIMIZATION_FLAGS}"`)
  - **Debian template**: Not used for compilation (pre-compiled packages), stored in labels for consistency
  - **Bundle template**: Used for compiling additional geospatial extensions
- `PGIS1_LTO_FLAGS`: Link-time optimization settings (enabled for production architectures)
  - **Alpine/Master templates**: Used during PostGIS configure step (`${PGIS1_LTO_FLAGS}`)
  - **Debian template**: Not used (pre-compiled packages), stored in labels for consistency
  - **Bundle template**: Used for extension compilation when applicable

### Registry Arguments (for Bundle Images)
- `REGISTRY`: Docker registry URL (e.g., `docker.io`) - only populated for bundle builds
- `REPO_NAME`: Repository name (e.g., `imresamu`) - only populated for bundle builds  
- `IMAGE_NAME`: Base image name with architecture suffix (e.g., `postgistest-amd64`)

### Docker Label Information
These build arguments are automatically converted to Docker labels in the final images:

#### Standard PostGIS Labels
- `org.postgis.base.optimization.flags`: Compiler optimization level
  - **Alpine/Master**: Actual compilation flags used (`-O3` for production, `-O1` for experimental)
  - **Debian**: Pre-compiled package optimization level (stored for consistency)
- `org.postgis.base.lto.flags`: Link-time optimization settings
  - **Alpine/Master**: Actual LTO flags used (`--enable-lto` for production architectures)
  - **Debian**: LTO status of pre-compiled packages (stored for consistency)
- `org.postgis.base.jit.status`: PostgreSQL JIT status (`enabled` or `disabled`)
  - **All templates**: Reflects JIT configuration for end users
- `org.postgis.base.regression.mode`: Regression test mode used
  - **Alpine/Master**: Actual test mode executed during build
  - **Debian**: Test mode that would be used (stored for consistency)

#### Bundle Image Labels  
- `org.postgis.bundle0.optimization.flags`: Bundle-specific optimization flags used for extension compilation
- `org.postgis.bundle0.lto.flags`: Bundle-specific LTO settings for extension compilation
- `org.postgis.bundle0.jit.status`: Bundle-specific JIT status inherited from base image

**JIT Status Logic**: JIT is automatically disabled (`disabled`) for architectures using `test_nojit` or `skip_nojit` modes, and enabled (`enabled`) for all others.

**Template-Specific Behavior**:
- **Alpine/Master templates**: Labels reflect actual build-time compilation settings
- **Debian template**: Labels store equivalent settings for consistency, but compilation flags don't affect the pre-compiled packages
- **Bundle template**: Labels reflect settings used for additional extension compilation

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
- **GitHub Actions Cache**: Persistent build cache with workflow + architecture-specific scoping
- **Docker Layer Caching**: Faster subsequent builds with zstd compression
- **Workflow Cache Isolation**: Each workflow (alp/deb/dev) has unique cache namespace to prevent conflicts
- **Native ARM Runners**: Direct ARM64 execution without emulation
- **Advanced QEMU Setup**: Gold standard QEMU configuration for cross-platform builds
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

### Cache Strategy (Updated July 2025)

#### Workflow Cache Isolation
To prevent cache conflicts when multiple workflows run simultaneously, the template implements a **unique cache namespace system**:

**Cache Tag Format:**
```yaml
# Current Week Cache (read+write):
${cache_registry}/${cache_repo_owner}/${cache_image_name}-${arch}:${workflow_id}-${family}-pg${version}-${iso_week}

# Previous Week Cache (fallback):
${cache_registry}/${cache_repo_owner}/${cache_image_name}-${arch}:${workflow_id}-${family}-pg${version}-${prev_iso_week}
```

**Automatic Cache Configuration:**
- **Cache Registry**: Defaults to `ghcr.io`
- **Cache Owner**: Automatically derived from `repo_name` input parameter
- **Cache Image**: Automatically derived as `{image_name}-cache`
- **PostgreSQL Prefix**: `pg17`, `pg16`, etc. for clarity

**Workflow Identifiers:**
- **Alpine**: `alp` - Alpine-based image builds
- **Debian**: `deb` - Debian-based image builds  
- **Development**: `dev` - Development/experimental builds

**Cache Examples:**
```yaml
# Alpine workflow cache (PostgreSQL 17, dynamically extracted):
ghcr.io/imresamu/postgistest-cache-amd64:alp-alpine-pg17-2025-W27
ghcr.io/imresamu/postgistest-cache-amd64:alp-alpine-pg17-2025-W26  # fallback

# Debian workflow cache (PostgreSQL 16, dynamically extracted):
ghcr.io/imresamu/postgistest-cache-amd64:deb-debian-pg16-2025-W27
ghcr.io/imresamu/postgistest-cache-amd64:deb-debian-pg16-2025-W26  # fallback

# Future PostgreSQL versions (automatically supported):
ghcr.io/imresamu/postgistest-cache-amd64:alp-alpine-pg19-2025-W27  # PostgreSQL 19
ghcr.io/imresamu/postgistest-cache-amd64:deb-debian-pg20-2025-W27  # PostgreSQL 20
```

#### Cache Strategy Benefits
- **Parallel Execution**: No cache write conflicts between workflows
- **ISO Week Rotation**: Automatic cleanup with ISO week tags (e.g., `2025-W27`)
- **Architecture Isolation**: Each architecture has its own cache repository
- **Workflow Isolation**: Each workflow has unique cache namespace  
- **PostgreSQL Isolation**: Each PostgreSQL version has separate cache (pg17, pg16, etc.)
- **2-Tier Fallback**: Current week → Previous week cache strategy
- **Automatic Configuration**: Cache names derived from input parameters
- **Weekly Cleanup**: Stale caches automatically expire

#### Implementation
Each workflow defines its cache identifier in the environment:
```yaml
env:
  WORKFLOW_CACHE_ID: "alp"  # or "deb" or "dev"
```

The template automatically uses this ID for all cache operations, ensuring complete isolation between workflows while maintaining efficient cache sharing within each workflow family.

### Cache Debug and Monitoring (Added July 2025)

The template includes comprehensive debug logging for cache operations to provide full visibility into the new cache isolation system:

#### Debug Information Levels

**1. Early Configuration Debug**
```yaml
=== Cache Configuration Debug ===
Workflow Cache ID: alp
Image Directory: 17-3.5/alpine3.22
Cache Repository: ghcr.io/imresamu/postgistest-cache
Week Tag: 2025-W27
Cache Format: {CACHE_REPO}-{ARCH}:{WORKFLOW_ID}-{FAMILY}-{PG_MAJOR}-{WEEK}
```

**2. Pre-Build Cache Tag Generation**
```yaml
=== Generated Cache Image Names ===
Read-Only Cache (broad): ghcr.io/imresamu/postgistest-cache-amd64:alp-alpine
Read-Write Cache (unique): ghcr.io/imresamu/postgistest-cache-amd64:alp-alpine-17-2025-W27
Previous Week Cache (fallback): ghcr.io/imresamu/postgistest-cache-amd64:alp-alpine-17-2025-W26
```

**3. Post-Build Cache Operation Results**
```yaml
=== Cache Operation Results ===
Build completed for: 17-3.5/alpine3.22 on amd64
Cache Images Used: [detailed cache targets]
Cache Hit/Miss Analysis: References to buildkit 'CACHED' vs 'DONE' indicators
Cache Repository Status: Verification of cache accessibility
```

**4. Final Cache Summary**
```yaml
=== Build Job Cache Summary ===
Job: amd64 | 17-3.5/alpine3.22
Workflow: alp (Recent [1/7])
Cache written to: ghcr.io/imresamu/postgistest-cache-amd64:alp-alpine-17-2025-W27
Cache Namespace Summary: All isolation levels confirmed
```

#### Debug Benefits
- **Full Cache Visibility**: Exact cache image names at every step
- **Strategy Validation**: Confirms all isolation levels are working
- **Troubleshooting Support**: References to buildkit cache indicators
- **Repository Status**: Verifies cache accessibility and existence
- **Workflow Isolation Confirmation**: Prevents namespace conflicts
- **Performance Insights**: Enables cache hit/miss analysis

#### Locating Debug Information
All cache debug information appears as separate workflow steps:
- `Debug - Check matrix variables and cache configuration`
- `Debug - Cache tags and configuration` (before build)
- `Debug - Cache operation results` (after build)
- `Debug - Final cache summary` (end of job)

This comprehensive debugging enables administrators to:
- Verify cache isolation is working correctly
- Troubleshoot cache-related build issues
- Monitor cache effectiveness across workflows
- Validate the new cache strategy implementation

## Advanced QEMU Configuration

The template implements a **gold standard QEMU setup** for reliable cross-platform builds on GitHub Actions, addressing common emulation issues with exotic architectures like s390x, mips64le, and ppc64le.

### QEMU Setup Strategy

#### Problem Analysis
Traditional QEMU setups often fail because:
1. **Buildx isolation**: `docker-container` driver runs in isolated container without access to host QEMU registrations
2. **binfmt-misc access**: QEMU handlers registered on host but not visible to Buildx builder
3. **Test environment separation**: Different environment between build and test phases
4. **Bootstrap timing**: QEMU handlers not properly loaded into builder

#### Solution Implementation

**1. Privileged Buildx Configuration**
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  with:
    install: true
    driver: docker-container
    driver-opts: |
      network=host
      privileged=true
    platforms: ${{ matrix.target }}
```

**Key improvements:**
- `driver: docker-container`: Explicit containerized driver for better control
- `privileged=true`: Grants access to host binfmt-misc QEMU registrations
- `network=host`: Maintains network performance

**2. Explicit Bootstrap**
```yaml
- name: Bootstrap Buildx builder to load QEMU handlers
  if: ${{ matrix.build_type == 'qemu' }}
  run: docker buildx inspect --bootstrap
```

**Purpose:**
- Forces Buildx to reload QEMU handlers into the builder
- Ensures QEMU registration is properly propagated
- Only runs for QEMU architectures (performance optimization)

**3. Test Environment QEMU Re-setup**
```yaml
- name: Ensure QEMU for testing
  if: ${{ matrix.build_type == 'qemu' }}
  uses: docker/setup-qemu-action@v3
  with:
    platforms: ${{ matrix.target }}
```

**Rationale:**
- Test phase uses `DOCKER_BUILDKIT=0` which may not inherit QEMU setup
- `docker run --platform` commands require host-level QEMU handlers
- Guarantees consistent emulation environment for both build and test

### Architecture-Specific Benefits

| Architecture | Previous Issues | QEMU Solution Benefits |
|--------------|----------------|------------------------|
| **s390x** | exec format error, test failures | Proper binfmt-misc access, stable emulation |
| **mips64le** | Container startup failures | Reliable QEMU handler loading |
| **ppc64le** | Platform detection issues | Consistent cross-platform behavior |
| **riscv64** | JIT compatibility problems | Better emulation + JIT disabled |

### Performance Impact

**Overhead Analysis:**
- **Native builds** (amd64, arm64): No QEMU setup → No performance impact
- **QEMU builds**: ~10-15 seconds additional setup time
- **Stability gain**: Significantly reduced emulation failures
- **Resource efficiency**: Fewer failed builds = better CI resource utilization

### Implementation Best Practices

**1. Conditional QEMU Setup**
```yaml
if: ${{ matrix.build_type == 'qemu' }}
```
- Only applies to architectures requiring emulation
- Native builds remain unaffected
- Optimal resource usage

**2. Platform Targeting**
```yaml
platforms: ${{ matrix.target }}
```
- Precise platform specification per job
- Avoids unnecessary QEMU registrations
- Reduces emulation overhead

**3. Bootstrap Timing**
- QEMU setup → Buildx setup → Bootstrap → Build → Test QEMU re-setup
- Ensures QEMU availability at each critical phase
- Prevents emulation gaps

## Error Handling

### Build Failures
- Individual architecture failures don't stop others
- Clear error reporting in emoji-based job names
- Comprehensive logging for debugging
- **QEMU failures**: Detailed emulation setup logging for troubleshooting

### Manifest Creation
- Validates all required images exist before manifest creation
- Sequential processing prevents race conditions
- Detailed error messages for troubleshooting

### QEMU Troubleshooting
- **Bootstrap failures**: Check runner privileges and QEMU installation
- **Platform errors**: Verify architecture spelling and platform mapping
- **Test emulation issues**: Confirm QEMU re-setup before test execution

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

## Concurrency Management

### Workflow-Level Concurrency Control

All active build workflows now include concurrency control to ensure only one instance runs at a time:

| Workflow | Concurrency Group | Behavior | Benefits |
|----------|------------------|----------|----------|
| **Alpine** | `alpine-builds` | Queue builds | Prevents QEMU resource conflicts |
| **Debian** | `debian-builds` | Queue builds | Avoids cache write conflicts |
| **Development** | `development-builds` | Queue builds | Ensures experimental stability |
| **RetryTest** | `retrytest-builds` | Queue builds | Prevents test interference |

### Concurrency Configuration

```yaml
concurrency:
  group: "workflow-specific-builds"
  cancel-in-progress: false  # false = queue, true = cancel previous
```

### Real-World Scenarios

#### Scenario 1: Push + Manual Trigger
```
1. Developer pushes code → Alpine build starts
2. Admin manually triggers Alpine build → Queued until #1 completes
3. Build #1 finishes → Build #2 starts automatically
```

#### Scenario 2: Schedule + Push Conflict
```
1. 02:00 UTC: Scheduled build starts
2. 02:15 UTC: Developer pushes → Build queued
3. 03:30 UTC: Scheduled build finishes → Push build starts
```

#### Scenario 3: Multiple Manual Triggers
```
1. Admin triggers Alpine build #1 → Starts immediately
2. Admin triggers Alpine build #2 → Queued (not canceled)
3. Admin triggers Alpine build #3 → Queued behind #2
4. Builds execute sequentially: #1 → #2 → #3
```

### Benefits

**Resource Protection:**
- Prevents GitHub Actions runner exhaustion
- Avoids Docker registry rate limiting
- Eliminates cache write conflicts

**Build Integrity:**
- Sequential execution ensures clean cache state
- No race conditions between builds
- Predictable resource allocation

**Cost Efficiency:**
- No wasted parallel builds that would conflict
- Efficient use of GitHub Actions minutes
- Reduced failed builds due to resource contention

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
**Schedule**: Tuesday 02:00 UTC (`cron: '0 2 * * 2'`)

The Alpine workflow builds Docker images for **8 architectures** across **7 priority-based sequential steps** with descending PostgreSQL version order (18→13):

| Step | Name | Dependencies | PostgreSQL Versions | Architectures | Image Count | Purpose |
|------|------|--------------|-------------------|---------------|-------------|---------|
| **1** | `Recent [1/7]` | None | 18 → 17 → 16 | 8 architectures | 3 directories | **Latest releases** - highest priority |
| **2** | `Legacy [2/7]` | Needs: Recent | 15 → 14 → 13 | 8 architectures | 3 directories | **Older PostgreSQL** - high priority |
| **3** | `3.22-3.6 [3/7]` | Needs: Legacy | 18 → 17 | 2 architectures | 2 directories | **PostGIS 3.6** - medium priority |
| **4** | `3.22-3.4 [4/7]` | Needs: 3.22-3.6 | 17 → 16 → 15 → 14 → 13 | 2 architectures | 5 directories | **PostGIS 3.4** - medium priority |
| **5** | `3.21-3.5 [5/7]` | Needs: 3.22-3.4 | 17 → 16 → 15 → 14 → 13 | 2 architectures | 5 directories | **Alpine 3.21** - low priority |
| **6** | `3.21-3.4 [6/7]` | Needs: 3.21-3.5 | 17 → 16 → 15 → 14 → 13 | 2 architectures | 5 directories | **Alpine 3.21** - low priority |
| **7** | `3.21-3.3 [7/7]` | Needs: 3.21-3.4 | 16 → 15 → 14 → 13 | 2 architectures | 4 directories | **Legacy PostGIS** - lowest priority |

**Key Features:**
- **Architecture Support**: 8 architectures (amd64, arm64, armv6, armv7, 386, ppc64le, riscv64, s390x)
- **PostGIS Version Isolation**: Each step uses unique PostGIS versions to prevent cache conflicts
- **Priority Execution**: Latest PostgreSQL/PostGIS combinations processed first
- **Step Progression**: Full 8-arch builds → Limited 2-arch builds for older combinations
- **Cache Optimization**: Workflow cache ID `"alp"` with complete isolation
- **QEMU Enhancement**: Advanced QEMU configuration for exotic architectures (s390x, mips64le)

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

| Workflow | Trigger | Schedule | Manual | Push/PR | Architecture Count | Cache ID |
|----------|---------|----------|--------|---------|--------------------|---------|
| **`workflow-build-debian.yml`** | Monday 02:00 UTC | 6 | 4 | 2 | 2 architectures (3 steps) | `deb` |
| **`workflow-build-alpine.yml`** | Tuesday 02:00 UTC | 8 | 6 | 4 | 8 architectures (7 steps) | `alp` |
| **`workflow-build-development.yml`** | Wednesday 02:00 UTC | 4 | 3 | 2 | 2+1 architectures (3 steps) | `dev` |

### Resource Utilization by Scenario

**Scheduled Runs (Weekdays 02:00 UTC):**
- Only 1 workflow active per day (priority: Debian → Alpine → Development)
- Maximum parallelism: Debian=6, Alpine=8, Development=4
- **Total resource usage**: 4-8 parallel builds (Alpine restored to 8 architectures with QEMU improvements)

**Manual Triggers:**
- 1-2 workflows typically active
- Moderate parallelism: Debian=4, Alpine=6, Development=3  
- **Total resource usage**: 3-10 parallel builds (Alpine back to full architecture support)

**Push/PR Events:**
- 2-3 workflows may trigger simultaneously
- Conservative parallelism: Debian=2, Alpine=4, Development=2
- **Total resource usage**: 2-8 parallel builds (resource-safe with enhanced QEMU stability)

This template-based approach provides a production-ready, maintainable, and efficient multi-architecture Docker build system optimized for reduced API usage and improved debugging capabilities.