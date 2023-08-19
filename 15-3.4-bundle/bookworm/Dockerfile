#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#       source: "Dockerfile.bundle.template"
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# set the base image
ARG REGISTRY=docker.io
ARG REPO_NAME=postgis
ARG IMAGE_NAME=postgis


FROM ${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}:15-3.4-bookworm AS builder

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      autoconf \
      automake \
      autotools-dev \
      bison \
      build-essential \
      cmake \
      g++ \
      git \
      make \
      postgresql-server-dev-$PG_MAJOR \
      pgxnclient \
      # MobilityDB
      libgeos++-dev \
      libgsl-dev \
      libjson-c-dev \
      libproj-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install: https://github.com/zachasme/h3-pg
RUN pgxn install h3

# Install MobilityDB
RUN    mkdir -p /MobilityDB \
    && git clone --depth 1 --branch v1.1.0-alpha https://github.com/MobilityDB/MobilityDB.git  /MobilityDB \
    && mkdir MobilityDB/build \
    && cd MobilityDB/build \
    && cmake -DCMAKE_BUILD_TYPE=Release \
             -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
             -DCMAKE_POLICY_DEFAULT_CMP0069=NEW \
             .. \
    && make \
    && make install



FROM ${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}:15-3.4-bookworm

LABEL maintainer="PostGIS Project - https://postgis.net" \
      org.opencontainers.image.description="PostGIS Bundle - 15-3.4-bookworm " \
      org.opencontainers.image.source="https://github.com/postgis/docker-postgis"


RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        lsb-release \
    # https://docs.timescale.com/self-hosted/latest/install/installation-linux/ \
    && echo "deb https://packagecloud.io/timescale/timescaledb/debian/ `lsb_release -c -s` main" | tee /etc/apt/sources.list.d/timescaledb.list \
    && wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | apt-key add - \
    \
    && apt-get purge -y --autoremove \
        wget \
        lsb-release \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-$PG_MAJOR-cron \
        postgresql-$PG_MAJOR-icu-ext \
        postgresql-$PG_MAJOR-ogr-fdw \
        postgresql-$PG_MAJOR-pgrouting \
        postgresql-$PG_MAJOR-pgrouting-scripts \
        postgresql-$PG_MAJOR-pgvector \
        postgresql-$PG_MAJOR-pointcloud \
        \
        postgis \
        postgresql-client-common \
        postgresql-common \
        postgresql-postgis \
        postgresql-plpython3-$PG_MAJOR \
        postgresql-postgis-scripts \
        \
        timescaledb-2-postgresql-$PG_MAJOR \
        timescaledb-tools \
        \
        # add MobilityDb missing dependency from libgsl-dev
        libgsl27 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install MobilityDB and h3 from builder
COPY --from=builder /usr/share/postgresql/$PG_MAJOR/extension/ /usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=builder /usr/lib/postgresql/$PG_MAJOR/lib          /usr/lib/postgresql/$PG_MAJOR/lib

# check dependencies
RUN set -ex \
   && ldd /usr/lib/postgresql/15/lib/h3.so | grep 'not found' && exit 1 || true \
   && ldd /usr/lib/postgresql/15/lib/h3_postgis.so | grep 'not found' && exit 1 || true \
   && ldd /usr/lib/postgresql/15/lib/libMobilityDB-1.1.so | grep 'not found' && exit 1 || true
