# 1. Version Management

This document covers the first phase of the build process: managing versions and creating the central `versions.json` configuration.

## Overview

The version management system tracks upstream PostgreSQL, PostGIS, and related geospatial libraries to automatically generate build configurations for all supported combinations.

## Core Components

### 1. Version Detection Script: `tools/versions.sh`
Fetches latest versions from upstream projects:
- PostgreSQL versions from official releases
- PostGIS versions from Debian/Alpine packages
- Related libraries (GEOS, PROJ, GDAL)
- Extension versions (pgRouting, H3, etc.)

### 2. Central Configuration: `versions.json`
Generated metadata file containing all build configurations:
- PostgreSQL major versions (13-18)
- PostGIS versions (3.3-3.6) 
- OS variants (Debian Bookworm/Bullseye, Alpine 3.21/3.22)
- Package versions and checksums
- Build parameters per variant

### 3. Locked Versions: `locked.yml`
Defines special locked versions for testing/compatibility:
- Specific version combinations for regression testing
- Compatibility matrices
- Version pinning for stability

## Version Management Workflow

### 1. Update Versions
```bash
# Fetch latest upstream versions
tools/versions.sh

# This updates versions.json with:
# - Latest PostgreSQL releases
# - Current PostGIS package versions
# - Updated dependency versions
```

### 2. Review Changes
```bash
# Check what versions changed
git diff versions.json

# Verify new version combinations are valid
# Check for breaking changes in dependencies
```

### 3. Test Version Matrix
```bash
# Validate version combinations
make validate-versions

# Test specific version before full build
make test-version PG_VERSION=17 POSTGIS_VERSION=3.5
```

## Version Configuration Structure

### PostgreSQL Version Support
- **Current Supported**: 13, 14, 15, 16, 17, 18 (beta)
- **Version Lifecycle**: Follow PostgreSQL release cycle
- **EOL Handling**: Remove versions when PostgreSQL EOL reached

### PostGIS Version Matrix
- **PostGIS 3.3**: Legacy support (PostgreSQL 13-16)
- **PostGIS 3.4**: Stable release (PostgreSQL 14-17)
- **PostGIS 3.5**: Current stable (PostgreSQL 15-18)
- **PostGIS 3.6**: Latest features (PostgreSQL 16-18)

### OS Variant Support
```yaml
# Debian variants
bookworm:  # Debian 12 (current stable)
  - PostgreSQL: 13-18
  - PostGIS: 3.3-3.6
  - Package source: apt.postgresql.org

bullseye:  # Debian 11 (oldstable)
  - PostgreSQL: 13-16
  - PostGIS: 3.3-3.5
  - Package source: apt.postgresql.org

# Alpine variants  
alpine3.22:  # Alpine 3.22 (current)
  - PostgreSQL: 15-18
  - PostGIS: 3.4-3.6
  - Build: Source compilation

alpine3.21:  # Alpine 3.21 (previous)
  - PostgreSQL: 13-17
  - PostGIS: 3.3-3.5
  - Build: Source compilation
```

## Adding New PostgreSQL Versions

### 1. Automatic Detection
```bash
# Run version detection
tools/versions.sh

# New PostgreSQL versions are automatically detected
# Check versions.json for new entries
```

### 2. Manual Addition
```bash
# Add specific PostgreSQL version support
make add-postgres-version PG_VERSION=19 POSTGIS_VERSION=3.6 TYPE=postgis

# TYPE options:
# - postgis: Standard PostGIS image
# - bundle: Bundle with additional extensions  
# - master: Development build from source
```

### 3. Validation
```bash
# Test new version combination
make test-version PG_VERSION=19 POSTGIS_VERSION=3.6

# Validate all version combinations
make validate-matrix
```

## Version Pinning and Stability

### Locked Versions (`locked.yml`)
Used for regression testing and compatibility validation:
```yaml
# Example locked configuration
locked_versions:
  postgresql_13_postgis_33:
    pg_version: "13.16"
    postgis_version: "3.3.4+dfsg-1~exp1.pgdg120+1"
    purpose: "Regression baseline"
    
  postgresql_17_postgis_35:
    pg_version: "17beta1"  
    postgis_version: "3.5.0+dfsg-1~exp1.pgdg120+1"
    purpose: "Latest stable testing"
```

### Version Constraints
- **PostgreSQL Beta**: Include beta versions for early testing
- **PostGIS Experimental**: Track experimental Debian packages
- **Dependency Compatibility**: Ensure GEOS/PROJ/GDAL compatibility
- **Security Updates**: Regular package version updates

## Environment Variables

Configure version management behavior:
```bash
# Override default version sources
export PG_VERSION_SOURCE="https://api.github.com/repos/postgres/postgres/releases"
export POSTGIS_VERSION_SOURCE="packages.debian.org"

# Version pinning
export PIN_PG_VERSION="17.1"
export PIN_POSTGIS_VERSION="3.5.0"

# Development mode
export INCLUDE_BETA_VERSIONS="true"
export INCLUDE_EXPERIMENTAL="true"
```

## Troubleshooting

### Common Issues

1. **Version Detection Fails**
   ```bash
   # Check upstream sources are accessible
   curl -s https://api.github.com/repos/postgres/postgres/releases
   
   # Verify tools/versions.sh permissions
   chmod +x tools/versions.sh
   ```

2. **Invalid Version Combinations**
   ```bash
   # Validate specific combination
   make validate-version PG_VERSION=17 POSTGIS_VERSION=3.3
   
   # Check compatibility matrix
   cat versions.json | jq '.compatibility_matrix'
   ```

3. **Package Version Mismatches**
   ```bash
   # Update package indices
   make update-package-info
   
   # Force version refresh
   rm versions.json && tools/versions.sh
   ```

## Next Steps

After version management is complete:
1. **Template Generation** → See [2-template-system.md](2-template-system.md)
2. **Workflow Execution** → See [3-workflow-system.md](3-workflow-system.md)

## Related Files

- `tools/versions.sh` - Version detection script
- `versions.json` - Generated version configuration
- `locked.yml` - Locked version definitions
- `Makefile` - Version management targets
- `.env.example` - Environment variable examples