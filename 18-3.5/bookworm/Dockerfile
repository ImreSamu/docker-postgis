#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "./tools/apply-templates.sh"
#       source: "./templates/Dockerfile.debian.template"
# PLEASE DO NOT EDIT IT DIRECTLY.
#
ARG PGIS1_BASE_IMAGE=postgres:18beta1-bookworm
ARG PGIS1_POSTGRES_MAJOR=18
ARG PGIS1_POSTGIS_VERSION=3.5.3+dfsg-1~exp1.pgdg120+1
ARG PGIS1_POSTGIS_MAJOR=3

# Multi-architecture build arguments (passed from GitHub Actions workflow for labeling only)
# Note: Debian images use pre-compiled packages, so optimization/compilation flags are not used
ARG PGIS1_REGRESSION_MODE=""        # PostGIS regression test mode (stored in labels for consistency)
ARG PGIS1_OPTIMIZATION_FLAGS=""     # Compiler optimization flags (not used - Debian packages are pre-compiled)
ARG PGIS1_LTO_FLAGS=""              # Link-time optimization flags (not used - Debian packages are pre-compiled)
ARG PGIS1_POSTGIS_REPOSITORY=""     # PostGIS source repository URL (stored in labels for consistency)

# usable for forking the image
ARG PGIS1_SOURCE_REPO="https://github.com/postgis/docker-postgis"
ARG PGIS1_MAINTAINER="PostGIS Project - https://postgis.net - ${PGIS1_SOURCE_REPO}/issues"

FROM ${PGIS1_BASE_IMAGE}

ARG PGIS1_POSTGRES_MAJOR
ARG PGIS1_POSTGIS_VERSION
ARG PGIS1_POSTGIS_MAJOR
ARG PGIS1_SOURCE_REPO
ARG PGIS1_MAINTAINER
ARG PGIS1_BASE_IMAGE

# Multi-architecture build arguments (re-declared after FROM)
ARG PGIS1_REGRESSION_MODE
ARG PGIS1_OPTIMIZATION_FLAGS  
ARG PGIS1_LTO_FLAGS
ARG PGIS1_POSTGIS_REPOSITORY

LABEL maintainer="${PGIS1_MAINTAINER}" \
      org.opencontainers.image.description="PostGIS ${PGIS1_POSTGIS_VERSION} spatial database extension with PostgreSQL ${PGIS1_POSTGRES_MAJOR} bookworm" \
      org.opencontainers.image.source="${PGIS1_SOURCE_REPO}" \
      org.opencontainers.image.version="${PGIS1_POSTGIS_VERSION}" \
      org.opencontainers.image.base.name="${PGIS1_BASE_IMAGE}" \
      \
      # child friendly image labels, so some duplicated labels expected
      org.postgis.base.maintainer="${PGIS1_MAINTAINER}" \
      org.postgis.base.description="PostGIS ${PGIS1_POSTGIS_VERSION} spatial database extension with PostgreSQL ${PGIS1_POSTGRES_MAJOR} bookworm" \
      org.postgis.base.source="${PGIS1_SOURCE_REPO}" \
      org.postgis.base.version="${PGIS1_POSTGIS_VERSION}" \
      org.postgis.base.extensions="postgis,postgis_raster,postgis_sfcgal,postgis_topology,postgis_tiger_geocoder,address_standardizer" \
      org.postgis.base.name="${PGIS1_BASE_IMAGE}" \
      org.postgis.base.optimization.flags="${PGIS1_OPTIMIZATION_FLAGS}" \
      org.postgis.base.lto.flags="${PGIS1_LTO_FLAGS}" \
      org.postgis.base.jit.status="$(case "${PGIS1_REGRESSION_MODE}" in test_nojit|skip_nojit) echo 'disabled';; *) echo 'enabled';; esac)" \
      org.postgis.base.source.repository="${PGIS1_POSTGIS_REPOSITORY}" \
      org.postgis.base.regression.mode="${PGIS1_REGRESSION_MODE}"

ENV POSTGIS_MAJOR=${PGIS1_POSTGIS_MAJOR}
ENV POSTGIS_VERSION=${PGIS1_POSTGIS_VERSION}

RUN set -eux \
    # Export Debian package environment for child images
    # This enables child images to use the same package versions for consistency
    # Usage in child images: source /usr/local/share/docker-postgis-env.sh
    && apt-get update \
    && POSTGIS_PACKAGE_VERSION=$(apt-cache madison postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR | head -1 | awk '{print $3}') \
    && echo "export POSTGIS_PACKAGE_VERSION=${POSTGIS_PACKAGE_VERSION}" > /usr/local/share/docker-postgis-env.sh \
    && echo "export PG_MAJOR=${PG_MAJOR}" >> /usr/local/share/docker-postgis-env.sh \
    && echo "export POSTGIS_MAJOR=${POSTGIS_MAJOR}" >> /usr/local/share/docker-postgis-env.sh \
    && echo "export POSTGIS_VERSION=${POSTGIS_VERSION}" >> /usr/local/share/docker-postgis-env.sh \
    && chmod +x /usr/local/share/docker-postgis-env.sh \
    \
    && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
    && apt-get install -y --no-install-recommends \
         # ca-certificates: for accessing remote raster files;
         #   fix: https://github.com/postgis/docker-postgis/issues/307
         ca-certificates \
         \
         postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
         postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
         postgis \
    && rm -rf /var/lib/apt/lists/*

# multiple LLVM existance is not allowed.
RUN set -eux \
    && dpkg -l | grep llvm \
    && llvm_count=$(dpkg -l | grep llvm | wc -l) \
    && if [ "$llvm_count" -ne 1 ]; then \
        echo "ERROR: Expected exactly 1 LLVM package, found $llvm_count. This may cause PostGIS compilation issues."; \
        echo "Installed LLVM packages:"; \
        dpkg -l | grep llvm; \
        exit 1; \
       fi \
    # Add installed package versions to environment export
    && dpkg -l | grep -E "(libgeos|libproj|libgdal|postgis)" | awk '{gsub(/[:.+-]/, "_", $2); print "export " $2 "=\"" $3 "\""}' >> /usr/local/share/docker-postgis-env.sh \
    && echo "# LLVM validation: passed (exactly 1 LLVM package found)" >> /usr/local/share/docker-postgis-env.sh \
    # Debug: show the generated environment file
    && echo "=== Generated docker-postgis-env.sh content ===" \
    && cat /usr/local/share/docker-postgis-env.sh \
    && echo "=== End of docker-postgis-env.sh ===" \
    # Test the generated environment file by sourcing it
    && echo "=== Testing docker-postgis-env.sh sourcing ===" \
    && . /usr/local/share/docker-postgis-env.sh \
    && echo "Successfully sourced docker-postgis-env.sh" \
    && echo "POSTGIS_PACKAGE_VERSION: ${POSTGIS_PACKAGE_VERSION}" \
    && echo "PG_MAJOR: ${PG_MAJOR}" \
    && echo "POSTGIS_MAJOR: ${POSTGIS_MAJOR}" \
    && echo "POSTGIS_VERSION: ${POSTGIS_VERSION}" \
    && echo "=== docker-postgis-env.sh test completed ==="

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
COPY ./update-postgis.sh /usr/local/bin
