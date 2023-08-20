#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#       source: "Dockerfile.bundle.template"
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# set the base image
ARG REGISTRY=docker.io
ARG REPO_NAME=imresamu
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
      # TimescaleDB
      libkrb5-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Install TimescaleDB from source ( no arm64 binary yet )
RUN    mkdir -p /MobilityDB \
    && git clone --depth 1 --branch 2.11.2 https://github.com/timescale/timescaledb.git  /timescaledb \
    && cd timescaledb \
    && ./bootstrap  -DCMAKE_BUILD_TYPE=Release \
                    -DSEND_TELEMETRY_DEFAULT=false \
                    -DREGRESS_CHECKS=false \
    && cd build \
    && make -j$(nproc) \
    && make install

# Install MobilityDB
RUN    mkdir -p /MobilityDB \
    && git clone --depth 1 --branch v1.1.0-alpha https://github.com/MobilityDB/MobilityDB.git  /MobilityDB \
    && mkdir MobilityDB/build \
    && cd MobilityDB/build \
    && cmake -DCMAKE_BUILD_TYPE=Release \
             -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
             -DCMAKE_POLICY_DEFAULT_CMP0069=NEW \
             .. \
    && make -j$(nproc) \
    && make install

# Install: https://github.com/zachasme/h3-pg
RUN pgxn install h3


FROM ${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}:15-3.4-bookworm

LABEL maintainer="PostGIS Project - https://postgis.net" \
      org.opencontainers.image.description="PostGIS Bundle - 15-3.4-bookworm " \
      org.opencontainers.image.source="https://github.com/postgis/docker-postgis"


RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-$PG_MAJOR-cron \
        postgresql-$PG_MAJOR-icu-ext \
        postgresql-$PG_MAJOR-ogr-fdw \
        postgresql-$PG_MAJOR-pg-failover-slots \
        postgresql-$PG_MAJOR-pgaudit \
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
        # add MobilityDb missing dependency from libgsl-dev
        libgsl27 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install MobilityDB and h3 from builder
COPY --from=builder /usr/share/postgresql/$PG_MAJOR/extension/ /usr/share/postgresql/$PG_MAJOR/extension/
COPY --from=builder /usr/lib/postgresql/$PG_MAJOR/lib          /usr/lib/postgresql/$PG_MAJOR/lib

# check dependencies
RUN set -ex \
   && ldd /usr/lib/postgresql/15/lib/h3*.so            | grep 'not found' && exit 1 || true \
   && ldd /usr/lib/postgresql/15/lib/timescaledb*.so   | grep 'not found' && exit 1 || true \   
   && ldd /usr/lib/postgresql/15/lib/libMobilityDB*.so | grep 'not found' && exit 1 || true

RUN set -eux; \
	cp -v /usr/share/postgresql/postgresql.conf.sample /usr/share/postgresql/postgresql.conf.sample.orig; \
	echo "shared_preload_libraries = 'postgis-3,timescaledb'" >>  /usr/share/postgresql/postgresql.conf.sample; \
    # MobilityDB recomendation
	echo "max_locks_per_transaction = 128" >>  /usr/share/postgresql/postgresql.conf.sample;

# TODO: more test:  shared_preload_libraries = 'postgis-3,timescaledb'
