#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "./tools/apply-templates.sh"
#       source: "./templates/Dockerfile.master.template"
# PLEASE DO NOT EDIT IT DIRECTLY.
#
# "Experimental"; solely for testing purposes. Anticipate frequent changes!
# This is a multi-stage Dockerfile, requiring a minimum Docker version of 17.05.

ARG PGIS1_BASE_IMAGE=postgres:14-bookworm

# usable for forking the image
ARG PGIS1_SOURCE_REPO="https://github.com/postgis/docker-postgis"
ARG PGIS1_MAINTAINER="PostGIS Project - https://postgis.net - ${PGIS1_SOURCE_REPO}/issues"

ARG PGIS1_POSTGIS_REPOSITORY=https://github.com/postgis/postgis.git
ARG PGIS1_GEOS_REPOSITORY=https://github.com/libgeos/geos.git
ARG PGIS1_GDAL_REPOSITORY=https://github.com/OSGeo/gdal.git
ARG PGIS1_PROJ_REPOSITORY=https://github.com/OSGeo/PROJ.git
ARG PGIS1_SFCGAL_REPOSITORY=https://gitlab.com/sfcgal/SFCGAL.git
ARG PGIS1_CGAL_REPOSITORY=https://github.com/CGAL/cgal.git

# Should valid git checkout ( SHA1, tags, branches )
ARG PGIS1_POSTGIS_CHECKOUT=tags/3.1.9
ARG PGIS1_GEOS_CHECKOUT=tags/3.6.6
ARG PGIS1_GDAL_CHECKOUT=tags/v3.6.4
ARG PGIS1_PROJ_CHECKOUT=tags/6.3.1
ARG PGIS1_SFCGAL_CHECKOUT=tags/v1.5.1
ARG PGIS1_CGAL_CHECKOUT=tags/v5.6

# Skip SHA1 check if PGIS1_*_CHECKOUT_SHA1 is empty or 'nocheck'
# Otherwise, verify that the commit hash matches
ARG PGIS1_POSTGIS_CHECKOUT_SHA1=95a641b1747721d7004c5f0133b918d034035319
ARG PGIS1_GEOS_CHECKOUT_SHA1=36ea3034fb8719a639a7e7727e54ec8ab2e8a196
ARG PGIS1_GDAL_CHECKOUT_SHA1=7ca88116f5a46d429251361634eb24629f315076
ARG PGIS1_PROJ_CHECKOUT_SHA1=0e993d9744ecaa2f146bf62c43aecc61809a43ef
ARG PGIS1_SFCGAL_CHECKOUT_SHA1=61f3b08ade49493b56c6bafa98c7c1f84addbc10
ARG PGIS1_CGAL_CHECKOUT_SHA1=de4fa0d7d57b5a997012f2804161386ff4bc0d0f

ARG PGIS1_BOOST_VERSION=1.74.0
ARG PGIS1_CMAKE_BUILD_TYPE=Release

ARG PGIS1_GDAL_BUILD=minimal
# Minimal GDAL build ; no arrow, no parquet, no extra dependencies

FROM ${PGIS1_BASE_IMAGE} as builder

WORKDIR /

ARG PGIS1_BOOST_VERSION
ARG PGIS1_CMAKE_BUILD_TYPE
ARG PGIS1_BASE_IMAGE
ENV PGIS1_BOOST_VERSION=${PGIS1_BOOST_VERSION}

# apt-get install
RUN set -eux \
    # Export build environment for child images
    && echo "export PGIS1_CMAKE_BUILD_TYPE=${PGIS1_CMAKE_BUILD_TYPE}" > /usr/local/share/docker-postgis-env.sh \
    && echo "export PGIS1_BOOST_VERSION=${PGIS1_BOOST_VERSION}" >> /usr/local/share/docker-postgis-env.sh \
    && echo "export PGIS1_BASE_IMAGE=${PGIS1_BASE_IMAGE}" >> /usr/local/share/docker-postgis-env.sh \
    && echo "export PGIS1_GDAL_BUILD=minimal" >> /usr/local/share/docker-postgis-env.sh \
    && chmod +x /usr/local/share/docker-postgis-env.sh \
    \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      libboost-atomic${PGIS1_BOOST_VERSION} \
      libboost-chrono${PGIS1_BOOST_VERSION} \
      libboost-date-time${PGIS1_BOOST_VERSION} \
      libboost-filesystem${PGIS1_BOOST_VERSION} \
      libboost-program-options${PGIS1_BOOST_VERSION} \
      libboost-serialization${PGIS1_BOOST_VERSION} \
      libboost-system${PGIS1_BOOST_VERSION} \
      libboost-test${PGIS1_BOOST_VERSION} \
      libboost-thread${PGIS1_BOOST_VERSION} \
      libboost-timer${PGIS1_BOOST_VERSION} \
      libcurl3-gnutls \
      libexpat1 \
      libgmp10 \
      libgmpxx4ldbl \
      libjson-c5 \
      libmpfr6 \
      libprotobuf-c1 \
      libtiff6 \
      libxml2 \
      sqlite3 \
      # build dependency
      autoconf \
      automake \
      autotools-dev \
      bison \
      build-essential \
      ca-certificates \
      cmake \
      g++ \
      git \
      libboost-all-dev \
      libcurl4-gnutls-dev \
      libgmp-dev \
      libjson-c-dev \
      libmpfr-dev \
      libpcre3-dev \
      libpq-dev \
      libprotobuf-c-dev \
      libsqlite3-dev \
      libtiff-dev \
      libtool \
      libxml2-dev \
      make \
      pkg-config \
      protobuf-c-compiler \
      xsltproc \
      # gdal+
      liblz4-dev \
      liblzma-dev \
      libwebp-dev \
      libzstd-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG PGIS1_CMAKE_BUILD_TYPE
ENV PGIS1_CMAKE_BUILD_TYPE=${PGIS1_CMAKE_BUILD_TYPE}

FROM builder as cgal-sfcgal-builder

# cgal & sfcgal
ARG PGIS1_SFCGAL_REPOSITORY
ENV PGIS1_SFCGAL_REPOSITORY ${PGIS1_SFCGAL_REPOSITORY}
ARG PGIS1_SFCGAL_CHECKOUT
ENV PGIS1_SFCGAL_CHECKOUT ${PGIS1_SFCGAL_CHECKOUT}
ARG PGIS1_SFCGAL_CHECKOUT_SHA1

ARG PGIS1_CGAL_REPOSITORY
ENV PGIS1_CGAL_REPOSITORY ${PGIS1_CGAL_REPOSITORY}
ARG PGIS1_CGAL_CHECKOUT
ENV PGIS1_CGAL_CHECKOUT ${PGIS1_CGAL_CHECKOUT}
ARG PGIS1_CGAL_CHECKOUT_SHA1

RUN set -eux \
    && cd /usr/src \
    && mkdir cgal \
    && cd cgal \
    && git init \
    && git remote add origin ${PGIS1_CGAL_REPOSITORY} \
    && git fetch --depth 1 origin ${PGIS1_CGAL_CHECKOUT} \
    && git checkout FETCH_HEAD \
    # Skip SHA1 check if PGIS1_CGAL_CHECKOUT_SHA1 is empty or 'nocheck'
    # Otherwise, verify that the commit hash matches PGIS1_CGAL_CHECKOUT_SHA1
    && if [ -z "${PGIS1_CGAL_CHECKOUT_SHA1}" ] \
       || [ "${PGIS1_CGAL_CHECKOUT_SHA1}" = "nocheck" ]; then \
         echo "Skipping CGAL SHA1 check"; \
       else \
         if [ "$(git rev-parse HEAD)" != "${PGIS1_CGAL_CHECKOUT_SHA1}" ]; then \
           echo "CGAL SHA1 problem! Stop!"; \
           exit 1; \
         fi; \
       fi \
    && git log -1 > /_pgis_cgal_last_commit.txt \
    && cd /usr/src \
    && mkdir SFCGAL \
    && cd SFCGAL \
    && git init \
    && git remote add origin ${PGIS1_SFCGAL_REPOSITORY} \
    && git fetch --depth 1 origin ${PGIS1_SFCGAL_CHECKOUT} \
    && git checkout FETCH_HEAD \
    # Skip SHA1 check if PGIS1_SFCGAL_CHECKOUT_SHA1 is empty or 'nocheck'
    # Otherwise, verify that the commit hash matches PGIS1_SFCGAL_CHECKOUT_SHA1
    && if [ -z "${PGIS1_SFCGAL_CHECKOUT_SHA1}" ] \
       || [ "${PGIS1_SFCGAL_CHECKOUT_SHA1}" = "nocheck" ]; then \
         echo "Skipping SFCGAL SHA1 check"; \
       else \
         if [ "$(git rev-parse HEAD)" != "${PGIS1_SFCGAL_CHECKOUT_SHA1}" ]; then \
           echo "SFCGAL SHA1 problem! Stop!"; \
           exit 1; \
         fi; \
       fi \
    && git log -1 > /_pgis_sfcgal_last_commit.txt \
    && mkdir cmake-build \
    && cd cmake-build \
    && cmake .. \
       -DCGAL_DIR=/usr/src/cgal \
       -DCMAKE_BUILD_TYPE=${PGIS1_CMAKE_BUILD_TYPE} \
       -DSFCGAL_BUILD_BENCH=OFF \
       -DSFCGAL_BUILD_EXAMPLES=OFF \
       -DSFCGAL_BUILD_TESTS=OFF \
       -DSFCGAL_WITH_OSG=OFF \
    && make -j$(nproc) \
    && make install \
    # clean
    && rm -fr /usr/src/SFCGAL \
    && rm -fr /usr/src/cgal


FROM builder as proj-builder

# proj
ARG PGIS1_PROJ_REPOSITORY
ENV PGIS1_PROJ_REPOSITORY ${PGIS1_PROJ_REPOSITORY}
ARG PGIS1_PROJ_CHECKOUT
ENV PGIS1_PROJ_CHECKOUT ${PGIS1_PROJ_CHECKOUT}
ARG PGIS1_PROJ_CHECKOUT_SHA1

RUN set -eux \
    && cd /usr/src \
    && mkdir PROJ \
    && cd PROJ \
    && git init \
    && git remote add origin ${PGIS1_PROJ_REPOSITORY} \
    && git fetch --depth 1 origin ${PGIS1_PROJ_CHECKOUT} \
    && git checkout FETCH_HEAD \
    # Skip SHA1 check if PGIS1_PROJ_CHECKOUT_SHA1 is empty or 'nocheck'
    # Otherwise, verify that the commit hash matches PGIS1_PROJ_CHECKOUT_SHA1
    && if [ -z "${PGIS1_PROJ_CHECKOUT_SHA1}" ] \
       || [ "${PGIS1_PROJ_CHECKOUT_SHA1}" = "nocheck" ]; then \
         echo "Skipping PROJ SHA1 check"; \
       else \
         if [ "$(git rev-parse HEAD)" != "${PGIS1_PROJ_CHECKOUT_SHA1}" ]; then \
           echo "PROJ SHA1 problem! Stop!"; \
           exit 1; \
         fi; \
       fi \
    && git log -1 > /_pgis_proj_last_commit.txt \
    # check the autotools exist? https://github.com/OSGeo/PROJ/pull/3027
    && if [ -f "autogen.sh" ] ; then \
        set -eux \
        && echo "autotools version: 'autogen.sh' exists! Older version!"  \
        && ./autogen.sh \
        && ./configure --disable-static \
        && make -j$(nproc) \
        && make install \
        ; \
    else \
        set -eux \
        && echo "cmake version: 'autogen.sh' does not exists! Newer version!" \
        && mkdir build \
        && cd build \
        && cmake .. -DCMAKE_BUILD_TYPE=${PGIS1_CMAKE_BUILD_TYPE} -DBUILD_TESTING=OFF \
        && make -j$(nproc) \
        && make install \
        ; \
    fi \
    \
    && rm -fr /usr/src/PROJ


FROM builder as geos-builder

# geos
ARG PGIS1_GEOS_REPOSITORY
ENV PGIS1_GEOS_REPOSITORY ${PGIS1_GEOS_REPOSITORY}
ARG PGIS1_GEOS_CHECKOUT
ENV PGIS1_GEOS_CHECKOUT ${PGIS1_GEOS_CHECKOUT}
ARG PGIS1_GEOS_CHECKOUT_SHA1

RUN set -eux \
    && cd /usr/src \
    && mkdir geos \
    && cd geos \
    && git init \
    && git remote add origin ${PGIS1_GEOS_REPOSITORY} \
    && git fetch --depth 1 origin ${PGIS1_GEOS_CHECKOUT} \
    && git checkout FETCH_HEAD \
    # Skip SHA1 check if PGIS1_GEOS_CHECKOUT_SHA1 is empty or 'nocheck'
    # Otherwise, verify that the commit hash matches PGIS1_GEOS_CHECKOUT_SHA1
    && if [ -z "${PGIS1_GEOS_CHECKOUT_SHA1}" ] \
       || [ "${PGIS1_GEOS_CHECKOUT_SHA1}" = "nocheck" ]; then \
         echo "Skipping GEOS SHA1 check"; \
       else \
         if [ "$(git rev-parse HEAD)" != "${PGIS1_GEOS_CHECKOUT_SHA1}" ]; then \
           echo "GEOS SHA1 problem! Stop!"; \
           exit 1; \
         fi; \
       fi \
    && git log -1 > /_pgis_geos_last_commit.txt \
    && mkdir cmake-build \
    && cd cmake-build \
    && cmake .. -DCMAKE_BUILD_TYPE=${PGIS1_CMAKE_BUILD_TYPE} -DBUILD_TESTING=OFF \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -fr /usr/src/geos


FROM builder as stage0-builder

COPY --from=cgal-sfcgal-builder /_pgis*.* /
COPY --from=cgal-sfcgal-builder /usr/local /usr/local

COPY --from=proj-builder /_pgis*.* /
COPY --from=proj-builder /usr/local /usr/local

COPY --from=geos-builder /_pgis*.* /
COPY --from=geos-builder /usr/local /usr/local
# gdal
ARG PGIS1_GDAL_REPOSITORY
ENV PGIS1_GDAL_REPOSITORY ${PGIS1_GDAL_REPOSITORY}
ARG PGIS1_GDAL_CHECKOUT
ENV PGIS1_GDAL_CHECKOUT ${PGIS1_GDAL_CHECKOUT}
ARG PGIS1_GDAL_CHECKOUT_SHA1


#

## GDAL_build-end

RUN set -eux \
    && ldconfig \
    && cd /usr/src \
    && mkdir gdal \
    && cd gdal \
    && git init \
    && git remote add origin ${PGIS1_GDAL_REPOSITORY} \
    && git fetch --depth 1 origin ${PGIS1_GDAL_CHECKOUT} \
    && git checkout FETCH_HEAD \
    # Skip SHA1 check if PGIS1_GDAL_CHECKOUT_SHA1 is empty or 'nocheck'
    # Otherwise, verify that the commit hash matches PGIS1_GDAL_CHECKOUT_SHA1
    && if [ -z "${PGIS1_GDAL_CHECKOUT_SHA1}" ] \
       || [ "${PGIS1_GDAL_CHECKOUT_SHA1}" = "nocheck" ]; then \
         echo "Skipping GDAL SHA1 check"; \
       else \
         if [ "$(git rev-parse HEAD)" != "${PGIS1_GDAL_CHECKOUT_SHA1}" ]; then \
           echo "GDAL SHA1 problem! Stop!"; \
           exit 1; \
         fi; \
       fi \
    && git log -1 > /_pgis_gdal_last_commit.txt \
    \
    # gdal project directory structure - has been changed !
    && if [ -d "gdal" ] ; then \
        echo "Directory 'gdal' dir exists -> older version!" ; \
        cd gdal ; \
    else \
        echo "Directory 'gdal' does not exists! Newer version! " ; \
    fi \
    \
    && if [ -f "./autogen.sh" ]; then \
        # Building with autoconf ( old/deprecated )
        set -eux \
        && ./autogen.sh \
        && ./configure --disable-static \
        ; \
    else \
        # Building with cmake
        set -eux \
        && mkdir build \
        && cd build \
        # config based on: https://salsa.debian.org/debian-gis-team/gdal/-/blob/master/debian/rules
        && cmake .. \
            -DCMAKE_BUILD_TYPE=${PGIS1_CMAKE_BUILD_TYPE} \
            -DBUILD_TESTING=OFF \
            -DBUILD_DOCS=OFF \
            \
            -DGDAL_HIDE_INTERNAL_SYMBOLS=ON \
            -DRENAME_INTERNAL_TIFF_SYMBOLS=ON \
            -DGDAL_USE_CURL=ON \
            -DGDAL_USE_DEFLATE=ON \
            -DGDAL_USE_EXPAT=ON \
            -DGDAL_USE_GEOS=ON \
            -DGDAL_USE_JSONC=ON \
            -DGDAL_USE_LIBLZMA=ON \
            -DGDAL_USE_LIBXML2=ON \
            -DGDAL_USE_LZ4=ON \
            -DGDAL_USE_POSTGRESQL=ON \
            -DGDAL_USE_SQLITE3=ON \
            -DGDAL_USE_TIFF=ON \
            -DGDAL_USE_WEBP=ON \
            -DGDAL_USE_ZLIB=ON \
            -DGDAL_USE_ZSTD=ON \
# minimal GDAL build ..
        ; \
    fi \
    \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -fr /usr/src/gdal

# Minimal command line test.
RUN set -eux \
    && ldconfig \
    && cs2cs \
    && ldd $(which gdalinfo) \
    && gdalinfo --version \
    && geos-config --version \
    && ogr2ogr --version \
    && proj \
    && sfcgal-config --version \
    && pcre-config  --version

# -------------------------------------------
# final stage
# -------------------------------------------
FROM ${PGIS1_BASE_IMAGE}

ARG PGIS1_SOURCE_REPO
ARG PGIS1_MAINTAINER
ARG PGIS1_BASE_IMAGE

LABEL maintainer="${PGIS1_MAINTAINER}" \
      org.opencontainers.image.description="PostGIS - 14-l3.1.9gcp spatial database extension with PostgreSQL 14 bookworm" \
      org.opencontainers.image.source="${PGIS1_SOURCE_REPO}" \
      org.opencontainers.image.version="14-l3.1.9gcp" \
      org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
      org.opencontainers.image.base.name="${PGIS1_BASE_IMAGE}" \
      \
      # child friendly image labels, so some duplacted labels expected
      org.postgis.base.maintainer="${PGIS1_MAINTAINER}" \
      org.postgis.base.description="PostGIS - 14-l3.1.9gcp spatial database extension with PostgreSQL 14 bookworm" \
      org.postgis.base.source="${PGIS1_SOURCE_REPO}" \
      org.postgis.base.version="14-l3.1.9gcp" \
      org.postgis.base.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
      org.postgis.base.extensions="postgis,postgis_raster,postgis_sfcgal,postgis_topology,postgis_tiger_geocoder,address_standardizer" \
      org.postgis.base.name="${PGIS1_BASE_IMAGE}" \
      org.postgis.base.repositories="POSTGIS:${PGIS1_POSTGIS_REPOSITORY},GEOS:${PGIS1_GEOS_REPOSITORY},GDAL:${PGIS1_GDAL_REPOSITORY},PROJ:${PGIS1_PROJ_REPOSITORY},SFCGAL:${PGIS1_SFCGAL_REPOSITORY},CGAL:${PGIS1_CGAL_REPOSITORY}"

ARG PGIS1_CMAKE_BUILD_TYPE
ARG PGIS1_BASE_IMAGE
ARG PGIS1_BOOST_VERSION

ENV PGIS1_CMAKE_BUILD_TYPE=${PGIS1_CMAKE_BUILD_TYPE} \
    PGIS1_BASE_IMAGE=${PGIS1_BASE_IMAGE} \
    PGIS1_BOOST_VERSION=${PGIS1_BOOST_VERSION}

RUN set -eux \
    # Update environment export with runtime packages
    && apt-get update \
    && BOOST_INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' libboost-atomic${PGIS1_BOOST_VERSION} 2>/dev/null || echo "not-found") \
    && echo "export BOOST_INSTALLED_VERSION=${BOOST_INSTALLED_VERSION}" >> /usr/local/share/docker-postgis-env.sh \
    && apt-get install -y -V --no-install-recommends \
      \
      curl \
      libboost-atomic${PGIS1_BOOST_VERSION} \
      libboost-chrono${PGIS1_BOOST_VERSION} \
      libboost-date-time${PGIS1_BOOST_VERSION} \
      libboost-filesystem${PGIS1_BOOST_VERSION} \
      libboost-program-options${PGIS1_BOOST_VERSION} \
      libboost-serialization${PGIS1_BOOST_VERSION} \
      libboost-system${PGIS1_BOOST_VERSION} \
      libboost-test${PGIS1_BOOST_VERSION} \
      libboost-thread${PGIS1_BOOST_VERSION} \
      libboost-timer${PGIS1_BOOST_VERSION} \
      libcurl3-gnutls \
      libexpat1 \
      libgmp10 \
      libgmpxx4ldbl \
      libjson-c5 \
      libmpfr6 \
      libpcre3 \
      libprotobuf-c1 \
      libtiff6 \
      libxml2 \
      sqlite3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=stage0-builder /_pgis*.* /
COPY --from=stage0-builder /usr/local /usr/local

# minimal GDAL build; so no need extra dependencies


ARG PGIS1_GDAL_CHECKOUT
ARG PGIS1_GDAL_REPOSITORY
ARG PGIS1_GEOS_CHECKOUT
ARG PGIS1_GEOS_REPOSITORY
ARG PGIS1_PROJ_CHECKOUT
ARG PGIS1_PROJ_REPOSITORY
ARG PGIS1_SFCGAL_CHECKOUT
ARG PGIS1_SFCGAL_REPOSITORY
ARG PGIS1_CGAL_REPOSITORY
ARG PGIS1_CGAL_CHECKOUT

ARG PGIS1_POSTGIS_CHECKOUT
ARG PGIS1_POSTGIS_REPOSITORY
ARG PGIS1_POSTGIS_CHECKOUT_SHA1

ENV PGIS1_GDAL_CHECKOUT=${PGIS1_GDAL_CHECKOUT} \
    PGIS1_GDAL_REPOSITORY=${PGIS1_GDAL_REPOSITORY} \
    PGIS1_GEOS_CHECKOUT=${PGIS1_GEOS_CHECKOUT} \
    PGIS1_GEOS_REPOSITORY=${PGIS1_GEOS_REPOSITORY} \
    PGIS1_PROJ_CHECKOUT=${PGIS1_PROJ_CHECKOUT} \
    PGIS1_PROJ_REPOSITORY=${PGIS1_PROJ_REPOSITORY} \
    PGIS1_CGAL_CHECKOUT=${PGIS1_CGAL_CHECKOUT} \
    PGIS1_CGAL_REPOSITORY=${PGIS1_CGAL_REPOSITORY} \
    PGIS1_SFCGAL_CHECKOUT=${PGIS1_SFCGAL_CHECKOUT} \
    PGIS1_SFCGAL_REPOSITORY=${PGIS1_SFCGAL_REPOSITORY} \
    PGIS1_POSTGIS_CHECKOUT=${PGIS1_POSTGIS_CHECKOUT} \
    PGIS1_POSTGIS_REPOSITORY=${PGIS1_POSTGIS_REPOSITORY}

# Minimal command line test ( fail fast )
RUN set -eux \
    && ldconfig \
    && cs2cs \
    && ldd $(which gdalinfo) \
    && gdalinfo --version \
    && gdal-config --formats \
    && geos-config --version \
    && ogr2ogr --version \
    && proj \
    && sfcgal-config --version \
    \
    # Testing ogr2ogr PostgreSQL driver.
    && ogr2ogr --formats | grep -q "PostgreSQL/PostGIS" && exit 0 \
            || echo "ogr2ogr missing PostgreSQL driver" && exit 1

# Specify GDAL_CONFIG and LD_LIBRARY_PATH for PostGIS build;
# The arm64 build is very senitive.
ENV GDAL_CONFIG /usr/local/bin/gdal-config
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# temporary workaround for : nitdb: invalid locale settings; check LANG and LC_* environment variables
#   https://github.com/docker-library/postgres/issues/1112#issuecomment-1746076388
RUN set -eux \
    && echo en_US.UTF-8 UTF-8 >> /etc/locale.gen && locale-gen

RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      autoconf \
      automake \
      autotools-dev \
      bison \
      build-essential \
      ca-certificates \
      cmake \
      docbook-xml \
      docbook5-xml \
      g++ \
      git \
      libboost-all-dev \
      libcunit1-dev \
      libcurl4-gnutls-dev \
      libgmp-dev \
      libjson-c-dev \
      libmpfr-dev \
      libpcre3-dev \
      libprotobuf-c-dev \
      libsqlite3-dev \
      libtiff-dev \
      libtool \
      libxml2-dev \
      libxml2-utils \
      make \
      pkg-config \
      postgresql-server-dev-$PG_MAJOR \
      protobuf-c-compiler \
      xsltproc \
    && cd \
    # postgis
    && cd /usr/src \
    && mkdir postgis \
    && cd postgis \
    && git init \
    && git remote add origin ${PGIS1_POSTGIS_REPOSITORY} \
    && git fetch --depth 1 origin ${PGIS1_POSTGIS_CHECKOUT} \
    && git checkout FETCH_HEAD \
    # Skip SHA1 check if PGIS1_POSTGIS_CHECKOUT_SHA1 is empty or 'nocheck'
    # Otherwise, verify that the commit hash matches PGIS1_POSTGIS_CHECKOUT_SHA1
    && if [ -z "${PGIS1_POSTGIS_CHECKOUT_SHA1}" ] \
       || [ "${PGIS1_POSTGIS_CHECKOUT_SHA1}" = "nocheck" ]; then \
         echo "Skipping POSTGIS SHA1 check"; \
       else \
         if [ "$(git rev-parse HEAD)" != "${PGIS1_POSTGIS_CHECKOUT_SHA1}" ]; then \
           echo "POSTGIS SHA1 problem! Stop!"; \
           exit 1; \
         fi; \
       fi \
    && git log -1 > /_pgis_last_commit.txt \
    && ldconfig \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
        --enable-lto \
    && make -j$(nproc) \
    && make install \
# refresh proj data - workarounds: https://trac.osgeo.org/postgis/ticket/5316
    && if command -v projsync >/dev/null 2>&1; then \
           projsync --system-directory --file ch_swisstopo_CHENyx06_ETRS \
        && projsync --system-directory --file us_noaa_eshpgn \
        && projsync --system-directory --file us_noaa_prvi \
        && projsync --system-directory --file us_noaa_wmhpgn ; \
    fi \
# regress check
    && mkdir /tempdb \
    && chown -R postgres:postgres /tempdb \
    && su postgres -c 'pg_ctl -D /tempdb init' \
    && su postgres -c 'pg_ctl -D /tempdb -c -l /tmp/logfile -o '-F' start ' \
    && ldconfig \
    && cd regress \
    && make -j$(nproc) check RUNTESTFLAGS=--extension PGUSER=postgres \
    \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_raster;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch; --needed for postgis_tiger_geocoder "' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS address_standardizer;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS address_standardizer_data_us;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;"' \
    && su postgres -c 'psql -t -c "SELECT version();"' >> /_pgis_full_version.txt \
    && su postgres -c 'psql -t -c "SELECT PostGIS_Full_Version();"' >> /_pgis_full_version.txt \
    && su postgres -c 'psql -t -c "\dx"' >> /_pgis_full_version.txt \
    \
    && su postgres -c 'pg_ctl -D /tempdb --mode=immediate stop' \
    && rm -rf /tempdb \
    && rm -rf /tmp/logfile \
    && rm -rf /tmp/pgis_reg \
# clean
    # Add final version information to environment export
    && echo "PostGIS build completed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> /usr/local/share/docker-postgis-env.sh \
    && find /_pgis*_commit.txt -type f -exec basename {} \; | while read commit_file; do \
         commit_hash=$(cat "/${commit_file}" | head -1 | awk '{print $2}') \
         && echo "export ${commit_file%.txt}=\"${commit_hash}\"" >> /usr/local/share/docker-postgis-env.sh; \
       done \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apt-get purge -y --autoremove \
      autoconf \
      automake \
      autotools-dev \
      bison \
      build-essential \
      cmake \
      docbook-xml \
      docbook5-xml \
      g++ \
      git \
      libboost-all-dev \
      libcurl4-gnutls-dev \
      libgmp-dev \
      libjson-c-dev \
      libmpfr-dev \
      libpcre3-dev \
      libprotobuf-c-dev \
      libsqlite3-dev \
      libtiff-dev \
      libtool \
      libxml2-dev \
      libxml2-utils \
      make \
      pkg-config \
      postgresql-server-dev-$PG_MAJOR \
      protobuf-c-compiler \
      xsltproc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
COPY ./update-postgis.sh /usr/local/bin

# last final test
RUN set -eux \
    && ldconfig \
    && cs2cs \
    && ldd $(which gdalinfo) \
    && gdalinfo --version \
    && gdal-config --formats \
    && geos-config --version \
    && ogr2ogr --version \
    && proj \
    && sfcgal-config --version \
    # check any missing dependencies
    && ldd /usr/lib/postgresql/$PG_MAJOR/lib/*.so | grep 'not found' && exit 1 || true \
    \
    # Is the "ca-certificates" package installed? (for accessing remote raster files)
    #   https://github.com/postgis/docker-postgis/issues/307
    && dpkg-query -W -f='${Status}' ca-certificates 2>/dev/null | grep -c "ok installed" \
    \
    # list last commits.
    && find /_pgis*_commit.txt -type f -print -exec cat {} \;  \
    # list postgresql, postgis version
    && cat _pgis_full_version.txt
