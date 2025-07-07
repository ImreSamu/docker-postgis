# 3. Workflow System

This document covers the third phase: GitHub Actions multi-architecture Docker builds, cache management, and manifest creation.

## Overview

The workflow system handles automated multi-architecture Docker image builds using GitHub Actions. It includes cache optimization, regression testing, and weekly cache cleanup to maintain efficiency and storage costs.

## Workflow Architecture

### Core Template: `template-workflow-multiarch.yml`

Reusable workflow template that provides:
- **Multi-architecture builds**: 9 architectures (amd64, arm64, armv6, armv7, 386, mips64le, ppc64le, riscv64, s390x)
- **Intelligent cache management**: Week-based cache rotation with workflow isolation
- **Regression testing**: Architecture-specific testing modes  
- **Manifest creation**: Efficient multi-arch manifest generation

### Group-Based Workflows

#### 🏔️ Alpine Group (`manifest-alpine.yml`)
- **Schedule**: Monday 02:00 UTC
- **Cache ID**: `alp` 
- **Sequential builds**: Recent→Legacy→3.22→3.21-3.5→3.21-3.4→3.21-3.3
- **Status**: Currently disabled (`.unused` extension)

#### 📦 Debian Group (`manifest-debian.yml`)  
- **Schedule**: Tuesday 02:00 UTC
- **Cache ID**: `deb`
- **Sequential builds**: Bookworm→Bundle0-Base→Bundle0-Images→Bullseye
- **Dependencies**: Bundle0 builds depend on Bookworm base images
- **Status**: Active for testing

#### 🔧 Other Group (`manifest-other.yml`)
- **Schedule**: Wednesday 02:00 UTC  
- **Cache ID**: `dev`
- **Sequential builds**: Recent→Master→Locked
- **Status**: Currently disabled (`.unused` extension)

## Architecture Configuration

### Architecture Support Matrix

| Architecture | Emoji | Runner | Platform | Regression Mode | Build Type | Optimization | LTO |
|--------------|-------|--------|----------|-----------------|------------|--------------|-----|
| **amd64** | 💻 | ubuntu-24.04 | linux/amd64 | require 🔒 | native ⚡ | -O3 -Wall | --enable-lto |
| **arm64** | 💪 | ubuntu-24.04-arm | linux/arm64 | require 🔒 | native ⚡ | -O3 -Wall | --enable-lto |
| **armv6** | 🦾 | ubuntu-24.04-arm | linux/arm/v6 | test 🔍 | qemu 🔄 | -O1 -Wall | - |
| **armv7** | 🤖 | ubuntu-24.04-arm | linux/arm/v7 | test 🔍 | qemu 🔄 | -O1 -Wall | - |
| **386** | 🖥️ | ubuntu-24.04 | linux/386 | test 🔍 | qemu 🔄 | -O1 -Wall | - |
| **mips64le** | 🎯 | ubuntu-24.04 | linux/mips64le | skip 💨 | qemu 🔄 | -O1 -Wall | - |
| **ppc64le** | ⚡ | ubuntu-24.04 | linux/ppc64le | skip 💨 | qemu 🔄 | -O1 -Wall | - |
| **riscv64** | 🧩 | ubuntu-24.04 | linux/riscv64 | test_nojit 🔍🐢 | qemu 🔄 | -O1 -Wall | - |
| **s390x** | 🏢 | ubuntu-24.04 | linux/s390x | skip 💨 | qemu 🔄 | -O1 -Wall | - |

### Regression Testing Modes
- **require** 🔒: Mandatory tests that must pass (production architectures)
- **test** 🔍: Standard regression tests, non-blocking if they fail  
- **test_nojit** 🔍🐢: Tests with JIT disabled for compatibility
- **skip** 💨: No regression tests (fastest builds)

### Build Optimizations
- **Production architectures** (amd64, arm64): `-O3` optimization with LTO enabled
- **Experimental architectures**: `-O1` optimization without LTO for stability
- **Native builds**: No QEMU emulation required (faster)
- **QEMU builds**: Cross-platform emulation for other architectures

## Cache Management System

### Cache Strategy (Updated July 2025)

#### Cache Repository Structure
```yaml
# Cache format:
ghcr.io/imresamu/postgistest-cache-{arch}:{workflow_id}-{family}-pg{version}-{ISO_week}

# Examples:
ghcr.io/imresamu/postgistest-cache-amd64:alp-alpine-pg17-2025-W27
ghcr.io/imresamu/postgistest-cache-arm64:deb-debian-pg16-2025-W26
ghcr.io/imresamu/postgistest-cache-riscv64:dev-alpine-pg15-2025-W25
```

#### Cache Isolation Strategy
- **Workflow isolation**: Each workflow (alp/deb/dev) has unique cache namespace
- **Architecture isolation**: Each arch writes to separate cache repository  
- **PostgreSQL isolation**: Each PG major version has unique cache tag
- **Week-based rotation**: ISO week provides automatic cache cleanup

#### Cache Benefits
- **Parallel execution**: No cache write conflicts between workflows
- **Efficient sharing**: Read cache shares within workflow+arch+family
- **Week-based rotation**: Automatic cleanup with ISO week tags
- **Storage optimization**: Prevents unlimited GHCR storage growth

### Cache Usage in Build

#### Build Step Cache Configuration
```yaml
- name: Build Docker image
  uses: docker/build-push-action@v6
  env:
    # Current week cache (read + write)
    RW_CACHE: ghcr.io/imresamu/postgistest-cache-amd64:deb-debian-pg17-2025-W27
    # Previous week cache for fallback (read-only)  
    RO_CACHE_PREV1W: ghcr.io/imresamu/postgistest-cache-amd64:deb-debian-pg17-2025-W26
  with:
    cache-from: |
      type=registry,ref=${{ env.RW_CACHE }}
      type=registry,ref=${{ env.RO_CACHE_PREV1W }}
    cache-to: |
      type=registry,ref=${{ env.RW_CACHE }},mode=max,compression=zstd
```

## Weekly Cache Cleanup

### Cache Cleanup Workflow: `cache-cleanup-weekly.yml`

#### Configuration
- **Schedule**: Every Sunday at 18:00 UTC
- **Retention Policy**: Keep last 4 ISO weeks of cache images
- **Coverage**: All architectures and workflow cache IDs
- **Cross-dependency**: ⚠️ Cleans cache created by `template-workflow-multiarch.yml`

#### Cleanup Process
```yaml
# 1. Calculate retention weeks
W1=$(date -u +%G-W%V)                    # Current week
W2=$(date -u -d "7 days ago" +%G-W%V)    # 1 week ago  
W3=$(date -u -d "14 days ago" +%G-W%V)   # 2 weeks ago
W4=$(date -u -d "21 days ago" +%G-W%V)   # 3 weeks ago

# 2. Create regex pattern
KEEP_PATTERN=".*-(2025-W27|2025-W26|2025-W25|2025-W24)$"

# 3. Delete old versions using GitHub Actions
uses: actions/delete-package-versions@v5
with:
  package-name: postgistest-cache-amd64
  package-type: container
  min-versions-to-keep: 4
  ignore-versions: '${{ KEEP_PATTERN }}'
```

#### Cleanup Coverage
```yaml
# All architectures cleaned up
architectures: [amd64, arm64, armv6, armv7, "386", mips64le, ppc64le, riscv64, s390x]

# All workflow cache IDs
cache_ids: [alp, deb, dev]  # Alpine, Debian, Development
```

### ⚠️ Important Cache Dependencies

1. **Cross-workflow dependency**: `cache-cleanup-weekly.yml` cleans cache created by `template-workflow-multiarch.yml`
2. **Naming consistency**: If cache naming is modified in `template-workflow-multiarch.yml`, update `cache-cleanup-weekly.yml` accordingly
3. **Fail-safe protection**: Minimum 4 versions are always kept, even if week calculation fails

## Build Arguments and Template Integration

### Build Arguments Passed to Dockerfiles
```yaml
build-args: |
  BUILDKIT_INLINE_CACHE=1
  PGIS1_REGRESSION_MODE=${{ matrix.regression_mode }}       # require/test/skip/test_nojit
  PGIS1_OPTIMIZATION_FLAGS=${{ matrix.optimization_flags }} # -O1/-O3 compiler flags
  PGIS1_LTO_FLAGS=${{ matrix.lto_flags }}                  # --enable-lto or empty
  REGISTRY=${{ env.REGISTRY }}                             # Docker registry URL
  REPO_NAME=${{ env.REPO_NAME }}                           # Repository name
  IMAGE_NAME=${{ env.IMAGE_NAME }}-${{ matrix.arch_variant }} # Architecture-specific image name
```

### Template Argument Usage
These arguments are used in Dockerfile templates for:
- **Labels**: Architecture and build metadata in Docker labels
- **Configuration**: JIT enable/disable based on regression mode
- **Compilation**: Optimization flags for source builds (Alpine/Bundle)
- **Dependencies**: Registry/repo information for bundle base images

## Workflow Execution Flow

### 1. Matrix Preparation
```yaml
prepare-matrix:
  # Generate build matrix from configuration
  # - Combine architectures × image directories  
  # - Set optimization flags per architecture
  # - Configure regression testing modes
  # - Check push conditions (branch/event)
```

### 2. Multi-Architecture Build
```yaml  
build-images:
  # For each architecture × image combination:
  # 1. Setup QEMU (if needed for emulation)
  # 2. Configure Docker Buildx with target platform
  # 3. Login to registries (Docker Hub + GHCR)
  # 4. Build with cache optimization
  # 5. Run regression tests
  # 6. Push architecture-specific images
```

### 3. Manifest Creation
```yaml
create-manifests:
  # Combine architecture-specific images into manifests:
  # 1. Use docker buildx imagetools create (optimized)
  # 2. Create manifests for all tags
  # 3. Test manifest integrity
  # 4. Reduce Docker Hub API calls by 75%
```

### 4. Cache Cleanup (Weekly)
```yaml
cleanup-cache:
  # Weekly cache maintenance:
  # 1. Calculate ISO week retention policy
  # 2. Clean up old cache for all architectures  
  # 3. List remaining cache versions
  # 4. Report cleanup results
```

## Job Naming Convention

Format: `{arch_emoji}{arch_name}|{regression_emoji}{image_dir}{build_type_emoji}`

### Examples
- `💻amd64|🔒17-3.5/bookworm⚡` - Native amd64, required tests, fast build
- `🧩riscv64|🔍🐢17-3.5/alpine3.22🔄` - QEMU riscv64, no-JIT tests, emulated build
- `💪arm64|🔒16-3.5/bundle0-bookworm⚡` - Native arm64, required tests, bundle image

## PostgreSQL Configuration for JIT-Incompatible Architectures

For `test_nojit` and `skip_nojit` modes, the build automatically modifies PostgreSQL configuration:

```bash
# Applied during build for JIT-incompatible architectures
echo "jit = off" >> /usr/local/share/postgresql/postgresql.conf.sample
```

This ensures end users get JIT disabled by default on architectures where it causes issues (riscv64, mips64le, s390x).

## Workflow Development and Testing

### 1. Template Development
```bash
# Edit workflow template
vi .github/workflows/template-workflow-multiarch.yml

# Validate workflow syntax
./actionlint .github/workflows/*.yml
```

### 2. Local Testing
```bash
# Test individual image build locally
make build-17-3.5-bookworm

# Test with architecture-specific build args
docker build \
  --build-arg PGIS1_REGRESSION_MODE=test \
  --build-arg PGIS1_OPTIMIZATION_FLAGS="-O1 -Wall" \
  17-3.5/bookworm/
```

### 3. Workflow Testing
```bash
# Trigger manual workflow run
gh workflow run manifest-debian.yml

# Monitor workflow progress  
gh run list --workflow=manifest-debian.yml

# Check workflow logs
gh run view --log
```

### 4. Cache Testing
```bash
# Manual cache cleanup trigger
gh workflow run cache-cleanup-weekly.yml

# Check cache repositories
gh api repos/imresamu/docker-postgis/packages/container/postgistest-cache-amd64/versions
```

## Troubleshooting

### Common Workflow Issues

#### 1. Cache Write Conflicts
```bash
# Error: Multiple workflows writing to same cache tag
# Solution: Check workflow_cache_id is unique per workflow

# Debug cache tags
echo "Workflow cache ID: alp vs deb vs dev"
grep -r "workflow_cache_id" .github/workflows/
```

#### 2. Build Arguments Not Found  
```bash
# Error: UndefinedVar in Dockerfile
# Solution: Check ARG re-declarations after FROM

# Debug build arguments
grep -A 10 "build-args:" .github/workflows/template-workflow-multiarch.yml
```

#### 3. Cross-Architecture Test Failures
```bash
# Error: Tests fail on emulated architectures
# Solution: Check regression mode and timeout settings

# Debug test configuration  
grep -r "POSTGRES_TEST_TRIES" .github/workflows/
```

#### 4. Manifest Creation Failures
```bash
# Error: Architecture-specific images not found
# Solution: Verify all builds completed successfully

# Debug manifest sources
docker buildx imagetools inspect postgistest-amd64:17-3.5-bookworm
```

### Cache Issues

#### 1. Cache Repository Not Found
```bash
# Error: Cache repository doesn't exist
# Solution: First build creates the repository automatically

# Verify cache repositories exist
gh api repos/imresamu/docker-postgis/packages
```

#### 2. Cache Cleanup Too Aggressive
```bash
# Error: All cache deleted unexpectedly  
# Solution: Check min-versions-to-keep failsafe

# Debug cache cleanup pattern
grep "keep_pattern" .github/workflows/cache-cleanup-weekly.yml
```

## Performance Optimizations

### 1. Build Performance
- **Native builds**: No QEMU for amd64/arm64 (2-3x faster)
- **QEMU optimization**: Only installed when needed
- **Cache efficiency**: 2-tier cache fallback (current + previous week)
- **Parallel limits**: Configurable based on trigger type

### 2. Registry Optimization  
- **Manifest creation**: Single API call instead of multiple commands
- **Cache compression**: zstd compression for smaller cache size
- **Push optimization**: Architecture-specific image names avoid conflicts

### 3. Resource Management
- **Max parallel builds**: Schedule (8), Manual (6), Push/PR (4)
- **Fail-fast strategy**: Stop other builds if critical architecture fails
- **Continue-on-error**: Cache operations don't fail entire workflow

## Monitoring and Reporting

### Build Status Monitoring
```bash
# Check all workflow runs
gh run list

# Monitor specific workflow
gh run list --workflow=manifest-debian.yml --limit=10

# Get detailed run information
gh run view <run-id> --log
```

### Cache Usage Monitoring
```bash
# List cache repositories
gh api repos/imresamu/docker-postgis/packages

# Check cache repository size  
gh api repos/imresamu/docker-postgis/packages/container/postgistest-cache-amd64

# Monitor cache cleanup results
gh run list --workflow=cache-cleanup-weekly.yml
```

## Next Steps

After workflow execution is complete:
1. **Version Management** ← See [1-version-management.md](1-version-management.md)
2. **Template System** ← See [2-template-system.md](2-template-system.md)  
3. **Production Deployment** → Deploy images to production registry

## Related Files

### Workflow Files
- `.github/workflows/template-workflow-multiarch.yml` - Core template
- `.github/workflows/manifest-debian.yml` - Debian group workflow
- `.github/workflows/manifest-alpine.yml.unused` - Alpine group (disabled)
- `.github/workflows/manifest-other.yml.unused` - Other group (disabled)
- `.github/workflows/cache-cleanup-weekly.yml` - Weekly cache cleanup

### Configuration Files  
- `versions.json` - Version input data
- `.env.example` - Environment variable configuration
- `test/postgis-config.sh` - Test configuration
- `Makefile` - Build automation targets