# 2. Template System

This document covers the second phase: template-based Dockerfile generation and the critical Docker ARG scoping issues.

## Overview

The template system generates individual Dockerfiles from Jinja2 templates using the version configurations from `versions.json`. This approach ensures consistency across all image variants while allowing customization per OS/architecture.

## Template Architecture

### Template Types

#### 1. Standard Templates
- **`Dockerfile.debian.template`**: Debian-based images using pre-compiled packages
- **`Dockerfile.alpine.template`**: Alpine-based images compiled from source
- **`Dockerfile.master.template`**: Development builds from upstream git repositories

#### 2. Extended Templates  
- **`Dockerfile.bundle0.template`**: Extended images with 40+ geospatial extensions
  - Includes: pgRouting, H3, MobilityDB, pgVector, TimescaleDB, DuckDB
  - Multi-stage builds with source compilation
  - Enterprise-grade package version locking

### Template Processing Flow

```bash
# 1. Read version configuration
versions.json → template processor

# 2. Generate per-variant Dockerfiles  
templates/ + versions.json → {PG_VERSION}-{POSTGIS_VERSION}/{OS_VARIANT}/

# 3. Create supporting files
- Dockerfile (generated from template)
- tags (space-separated Docker tags)
- initdb-*.sh (database initialization)
- update-postgis.sh (PostGIS upgrade script)
```

## Template Generation Commands

### Primary Command: `./update.sh`
Complete regeneration of all files:
```bash
# Full update: versions + templates + configurations
./update.sh

# This runs:
# 1. tools/versions.sh (update versions.json)
# 2. tools/apply-templates.sh (generate Dockerfiles)  
# 3. Additional configuration updates
```

### Template-Only Updates: `./tools/apply-templates.sh`
**⚠️ CRITICAL**: Use this after template modifications:
```bash
# Regenerate Dockerfiles from templates only
./tools/apply-templates.sh

# Use when:
# - Modifying template files
# - Fixing Docker ARG issues
# - Updating template logic
# - Testing template changes
```

## Critical Docker ARG Scoping Issue (July 2025)

### The Problem
Docker ARG variables declared before `FROM` are only available for the `FROM` instruction itself. In multi-stage builds, they must be re-declared after `FROM` to be used in subsequent build stages.

### Error Example
```dockerfile
# BEFORE (broken)
ARG PGIS1_REGRESSION_MODE
ARG PGIS1_POSTGIS_REPOSITORY

FROM postgres:17-bookworm

# These variables are now undefined!
LABEL org.postgis.regression.mode="${PGIS1_REGRESSION_MODE}"  # ❌ UndefinedVar
```

### Solution Applied
Fixed in `templates/Dockerfile.debian.template` (lines 26-30):
```dockerfile
# AFTER (fixed)
ARG PGIS1_REGRESSION_MODE
ARG PGIS1_POSTGIS_REPOSITORY

FROM postgres:17-bookworm

# Multi-architecture build arguments (re-declared after FROM)
ARG PGIS1_REGRESSION_MODE        # ✅ Re-declared
ARG PGIS1_OPTIMIZATION_FLAGS  
ARG PGIS1_LTO_FLAGS
ARG PGIS1_POSTGIS_REPOSITORY     # ✅ Re-declared

# Now variables are available
LABEL org.postgis.regression.mode="${PGIS1_REGRESSION_MODE}"  # ✅ Works
```

### Template Verification Status
- ✅ **`Dockerfile.debian.template`**: Fixed (ARG re-declarations added)
- ✅ **`Dockerfile.alpine.template`**: Already correct
- ✅ **`Dockerfile.bundle0.template`**: Already correct  
- ✅ **`Dockerfile.master.template`**: Already correct

## Template Development Workflow

### 1. Template Modification
```bash
# Edit template file
vi templates/Dockerfile.debian.template

# Test template syntax (Jinja2 validation)
make validate-templates
```

### 2. Regenerate Dockerfiles
```bash
# IMPORTANT: Use apply-templates.sh, not update.sh
./tools/apply-templates.sh

# Verify changes
git diff 17-3.5/bookworm/Dockerfile
```

### 3. Test Generated Dockerfiles
```bash
# Test specific variant
make build-17-3.5-bookworm

# Test Docker ARG variables
docker build --build-arg PGIS1_REGRESSION_MODE=test 17-3.5/bookworm/
```

### 4. Validate with Linters
```bash
# Check Dockerfile syntax
make lint-dockerfiles

# Validate workflow ARG usage
./actionlint .github/workflows/*.yml
```

## Template Variables and Context

### Available Template Variables
```jinja2
# Version information
{{ .[env.variant].PG_DOCKER }}      # PostgreSQL Docker tag
{{ .[env.variant].PG_MAJOR }}       # PostgreSQL major version  
{{ .[env.variant].POSTGIS_VERSION }} # PostGIS package version
{{ .[env.variant].POSTGIS_MAJOR }}  # PostGIS major version

# Environment context
{{ env.variant }}                   # OS variant (bookworm, alpine3.22)
{{ env.REGISTRY }}                  # Docker registry URL
{{ env.REPO_NAME }}                 # Repository name
{{ env.IMAGE_NAME }}                # Base image name

# Conditional logic
{{ if env.version | startswith("17") then ( -}}
  # PostgreSQL 17 specific content
{{ ) else ( -}}
  # Other versions
{{ ) end -}}
```

### Multi-Architecture Build Arguments
These are passed from GitHub Actions workflows:
```dockerfile
# Template declares these arguments
ARG PGIS1_REGRESSION_MODE=""        # PostGIS test mode (require/test/skip)
ARG PGIS1_OPTIMIZATION_FLAGS=""     # Compiler flags (-O1/-O3)  
ARG PGIS1_LTO_FLAGS=""              # Link-time optimization
ARG PGIS1_POSTGIS_REPOSITORY=""     # PostGIS source repo URL

# Workflow passes actual values
PGIS1_REGRESSION_MODE=require
PGIS1_OPTIMIZATION_FLAGS=-O3 -Wall -fno-omit-frame-pointer
PGIS1_LTO_FLAGS=--enable-lto
```

## Template Customization Examples

### 1. Adding New Build Argument
```dockerfile
# 1. Declare before FROM
ARG PGIS1_NEW_FEATURE=""

# 2. Re-declare after FROM  
FROM ${PGIS1_BASE_IMAGE}
ARG PGIS1_NEW_FEATURE

# 3. Use in build logic
RUN if [ "$PGIS1_NEW_FEATURE" = "enabled" ]; then \
      echo "Feature enabled"; \
    fi
```

### 2. OS-Specific Conditional Logic
```jinja2
{{ if env.variant | startswith("alpine") then ( -}}
# Alpine-specific packages
RUN apk add --no-cache alpine-package
{{ ) else ( -}}
# Debian-specific packages  
RUN apt-get update && apt-get install -y debian-package
{{ ) end -}}
```

### 3. Version-Specific Features
```jinja2
{{ if env.version | startswith("17") then ( -}}
# PostgreSQL 17 has new feature X
RUN echo "shared_preload_libraries = 'new_feature'" >> postgresql.conf
{{ ) else ( -}}
# Older versions use legacy approach
RUN echo "shared_preload_libraries = 'legacy_module'" >> postgresql.conf  
{{ ) end -}}
```

## Directory Structure After Generation

```
{PG_VERSION}-{POSTGIS_VERSION}/{OS_VARIANT}/
├── Dockerfile              # Generated from template
├── tags                    # Space-separated Docker tags
├── initdb-postgis.sh       # PostGIS initialization
├── update-postgis.sh       # PostGIS update script
└── initdb-bundle0.sh       # Bundle-specific initialization (bundle only)
```

### Example Generated Structure
```
17-3.5/
├── bookworm/
│   ├── Dockerfile          # From Dockerfile.debian.template
│   ├── tags                # "17-3.5-bookworm latest"
│   ├── initdb-postgis.sh
│   └── update-postgis.sh
├── alpine3.22/
│   ├── Dockerfile          # From Dockerfile.alpine.template  
│   ├── tags                # "17-3.5-alpine3.22"
│   └── initdb-postgis.sh
└── bundle0-bookworm/
    ├── Dockerfile          # From Dockerfile.bundle0.template
    ├── tags                # "17-3.5-bundle0-bookworm"
    ├── initdb-postgis.sh
    └── initdb-bundle0.sh
```

## Common Template Issues and Solutions

### 1. Undefined Variable Errors
```bash
# Error: Variables should be defined before their use
# Solution: Add ARG re-declaration after FROM

# Debug: Check which variables are undefined
grep -n "PGIS1_" templates/Dockerfile.debian.template
```

### 2. Jinja2 Syntax Errors
```bash
# Error: Template parsing fails
# Solution: Validate Jinja2 syntax

# Debug template syntax
python3 -c "
import jinja2
template = jinja2.Template(open('templates/Dockerfile.debian.template').read())
print('Template syntax OK')
"
```

### 3. Missing Template Variables
```bash
# Error: Variable not found in template context
# Solution: Check versions.json has required keys

# Debug available variables
jq '.variants | keys' versions.json
```

## Testing Templates

### 1. Syntax Validation
```bash
# Validate all templates
make validate-templates

# Test specific template
make test-template TEMPLATE=debian VARIANT=bookworm
```

### 2. Build Testing
```bash
# Test generated Dockerfile builds
make build-17-3.5-bookworm

# Test with build arguments
docker build \
  --build-arg PGIS1_REGRESSION_MODE=test \
  --build-arg PGIS1_OPTIMIZATION_FLAGS="-O1 -Wall" \
  17-3.5/bookworm/
```

### 3. Multi-Architecture Testing
```bash
# Test cross-platform build
docker buildx build \
  --platform linux/arm64 \
  --build-arg PGIS1_REGRESSION_MODE=test_nojit \
  17-3.5/alpine3.22/
```

## Next Steps

After template generation is complete:
1. **Version Management** ← See [1-version-management.md](1-version-management.md)  
2. **Workflow Execution** → See [3-workflow-system.md](3-workflow-system.md)

## Related Files

- `templates/` - Template directory
  - `Dockerfile.debian.template`
  - `Dockerfile.alpine.template` 
  - `Dockerfile.bundle0.template`
  - `Dockerfile.master.template`
- `tools/apply-templates.sh` - Template processor
- `update.sh` - Full update script
- `versions.json` - Template input data
- `{PG}-{POSTGIS}/{VARIANT}/` - Generated output directories