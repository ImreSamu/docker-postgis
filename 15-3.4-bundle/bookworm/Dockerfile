#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#       source: "Dockerfile.bundle.template"
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# set the base image
ARG REGISTRY=docker.io
ARG REPO_NAME=postgis
ARG IMAGE_NAME=postgis

FROM ${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}:15-3.4-bookworm

LABEL maintainer="PostGIS Project - https://postgis.net" \
      org.opencontainers.image.description="PostGIS Bundle - 15-3.4-bookworm " \
      org.opencontainers.image.source="https://github.com/postgis/docker-postgis"

# https://docs.timescale.com/self-hosted/latest/install/installation-linux/
#RUN echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | sudo tee /etc/apt/sources.list.d/timescaledb.list \
#    && wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
#        timescaledb-2-postgresql-$PG_MAJOR \
        \
        postgresql-$PG_MAJOR-cron \
        postgresql-$PG_MAJOR-icu-ext \
        postgresql-$PG_MAJOR-ogr-fdw \
        postgresql-$PG_MAJOR-pgq3 \
        postgresql-$PG_MAJOR-pgrouting \
        postgresql-$PG_MAJOR-pgrouting-scripts \
        postgresql-$PG_MAJOR-pgvector \
#       postgresql-$PG_MAJOR-pointcloud \
        \
        postgis \
        postgresql-client-common \
        postgresql-common \
        postgresql-plpython3-$PG_MAJOR \
        postgresql-postgis-scripts \
    && rm -rf /var/lib/apt/lists/*

# TODO: add h3-pg https://github.com/zachasme/h3-pg
# TODO: add MobilityDB
# TODO: add TimescaleDB ??
