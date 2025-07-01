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

| Architecture | Docker Platform | Runner | Emoji | Regression Mode | Use Case |
|--------------|-----------------|--------|-------|-----------------|----------|
| amd64        | linux/amd64     | ubuntu-24.04 | 💻 | require | Intel/AMD 64-bit (Production) |
| arm64        | linux/arm64     | ubuntu-24.04-arm | 💪 | require | Apple Silicon, AWS Graviton (Production) |
| armv6        | linux/arm/v6    | ubuntu-24.04-arm | 🦾 | test | Raspberry Pi Zero (Experimental) |
| armv7        | linux/arm/v7    | ubuntu-24.04-arm | 🤖 | test | Raspberry Pi 2/3/4 (Experimental) |
| 386          | linux/386       | ubuntu-24.04 | 🖥️ | test | Legacy 32-bit Intel (Experimental) |
| ppc64le      | linux/ppc64le   | ubuntu-24.04 | ⚡ | test | IBM POWER systems (Experimental) |
| riscv64      | linux/riscv64   | ubuntu-24.04 | 🧩 | test | RISC-V 64-bit (Experimental) |
| s390x        | linux/s390x     | ubuntu-24.04 | 🏢 | test | IBM mainframes (Experimental) |

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
- `ARCH_REGRESSION_MODES`: Maps architectures to regression testing modes (skip/test/require)
- `ARCH_ANNOTATIONS`: Maps architectures to manifest annotation metadata

#### Image Configuration
- `IMAGE_DIRECTORIES`: JSON array of directories to build (auto-updated by `tools/apply-ci.sh`)

### Adding New Architectures

To add support for new architectures:

1. **Add to `SUPPORTED_ARCHITECTURES`**:
   ```yaml
   SUPPORTED_ARCHITECTURES: '["amd64", "arm64", "new_arch"]'
   ```

2. **Configure mappings** in all five mapping objects:
   ```yaml
   ARCH_RUNNERS: '{"new_arch": "ubuntu-24.04"}'
   ARCH_PLATFORMS: '{"new_arch": "linux/new_arch"}'
   ARCH_EMOJIS: '{"new_arch": "🔥"}'
   ARCH_REGRESSION_MODES: '{"new_arch": "test"}'
   ARCH_ANNOTATIONS: '{"new_arch": {"os": "linux", "arch": "new_arch"}}'
   ```

3. **No code changes required** - the workflow dynamically generates the build matrix

## Regression Testing Modes

The workflow supports three regression testing modes for PostGIS builds:

### Mode Descriptions

| Mode | Description | Behavior | Log Storage | Use Case |
|------|-------------|----------|-------------|----------|
| `skip` | No regression tests | Tests are completely skipped | None | Fast builds, debugging |
| `test` | Non-blocking tests | Tests run but failures don't fail the build | Compressed with zstd --long | Development, experimental architectures |
| `require` | Blocking tests | Tests must pass or build fails | None (tests must pass) | Production architectures |

### Architecture-Specific Modes

- **Production Architectures** (`amd64`, `arm64`): Use `require` mode
  - Tests must pass for build to succeed
  - Ensures production image quality
  - No log storage needed (tests pass or build fails)

- **Experimental Architectures** (all others): Use `test` mode  
  - Tests run to catch issues early
  - Build continues even if tests fail
  - Regression logs saved compressed for debugging
  - Enables development on new architectures

### Log Management

For `test` mode, regression test logs are:
- Captured during build execution (visible in build output)
- Compressed using `zstd -3 --long` for optimal size
- Stored as `/_pgis_regression_test.log.zst` in the final image
- Can be extracted with: `zstd -dc /_pgis_regression_test.log.zst`

### Template Integration

The regression testing is controlled via Dockerfile template build argument:
```dockerfile
ARG PGIS1_REGRESSION_MODE=require
```

This argument is automatically set by the workflow based on the architecture being built.

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
- **Purpose**: Provides comprehensive build results
- **Features**:
  - Success/failure status for each phase
  - Architecture support summary
  - Registry configuration details
  - Always runs regardless of job failures

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