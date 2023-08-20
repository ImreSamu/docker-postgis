# postgis/postgis

[![Build Status](https://github.com/postgis/docker-postgis/workflows/Docker%20PostGIS%20CI/badge.svg)](https://github.com/postgis/docker-postgis/actions) [![Join the chat at https://gitter.im/postgis/docker-postgis](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/postgis/docker-postgis?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

The `postgis/postgis` image provides tags for running Postgres with [PostGIS](http://postgis.net/) extensions installed. This image is based on the official [`postgres`](https://registry.hub.docker.com/_/postgres/) image and provides debian and alpine variants for PostGIS 3.4.x, which is compatible with PostgreSQL versions 12, 13, 14, 15, and 16beta3. For PostgreSQL version 11, the image supports PostGIS 3.3, as it is not compatible with PostGIS 3.4.  Additionally, an image version is provided which is built from the latest two versions of Postgres (14, 15) with versions of PostGIS and its dependencies built from their respective master branches.

This image ensures that the default database created by the parent `postgres` image will have the following extensions installed:

| installed extensions | [initialized](https://github.com/postgis/docker-postgis/blob/master/initdb-postgis.sh)|
|---------------------|-----|
| `postgis`           | yes |
| `postgis_topology`  | yes |
| `postgis_tiger_geocoder` | yes |
| `postgis_raster` | |
| `postgis_sfcgal` | |
| `address_standardizer`| |
| `address_standardizer_data_us`| |

Unless `-e POSTGRES_DB` is passed to the container at startup time, this database will be named after the admin user (either `postgres` or the user specified with `-e POSTGRES_USER`). If you would prefer to use the older template database mechanism for enabling PostGIS, the image also provides a PostGIS-enabled template database called `template_postgis`.

## Versions (2023-08-20)

We provide multi-platform image support for the following architectures:

- `amd64`: Also known as X86-64. Use `--platform=linux/amd64` when specifying the platform.
- `arm64`: Also known as AArch64. Use `--platform=linux/arm64` when specifying the platform.

Notes:

- The `arm64` architecture support is still experimental. Please refer to the 'arch' column in the version information to determine whether an `arm64` version is available for a specific release.
- We currently do not support 32-bit architectures. Our images are only available for 64-bit architectures.

### Recommended Versions for New Users

For those new to PostGIS, we recommend the following image versions:

- `postgis/postgis:15-3.4`: This image includes a minimal setup of PostgreSQL with the PostGIS extension.
- `postgis/postgis:15-3.4-bundle`: This image includes additional geospatial-related extras along with PostgreSQL and PostGIS.

### Debian - bookworm  (recommended)

- This Docker-PostGIS version has a cautious release cycle to guarantee high stability.
  - By "cautious", we mean it does not always have the latest versions of geos, proj, gdal, and sfcgal packages.
- We use PostGIS, geos, proj, gdal, and sfcgal packages from the Debian repository.
  - In the Debian Bullseye repository, the versions are: geos=3.9, gdal=3.2, proj=7.2, and sfcgal=1.3.9.
- This version is easy to extend and has matured over time.
- PostgreSQL 11 is not compatible with PostGIS 3.4, so it remains on PostGIS 3.3. Please note that after November 9, 2023, PostgreSQL 11 will reach its [end-of-life (EOL)](https://www.postgresql.org/support/versioning/) and will no longer receive support.

<!-- bookworm_begin  -->
| `imresamu/postgis:` tags | Dockerfile | Arch | OS | Postgres | PostGIS |
| ---- | :-: | :-: | :-: | :-: | :-: |
| [`11-3.3-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=11-3.3-bookworm), [`11-3.3.4-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=11-3.3.4-bookworm), [`11-3.3`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=11-3.3) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/11-3.3/bookworm/Dockerfile) | amd64 arm64 | bookworm | 11 | 3.3.4 |
| [`12-3.4-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4-bookworm), [`12-3.4.0-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4.0-bookworm), [`12-3.4`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/12-3.4/bookworm/Dockerfile) | amd64 arm64 | bookworm | 12 | 3.4.0 |
| [`13-3.4-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4-bookworm), [`13-3.4.0-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4.0-bookworm), [`13-3.4`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/13-3.4/bookworm/Dockerfile) | amd64 arm64 | bookworm | 13 | 3.4.0 |
| [`14-3.4-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4-bookworm), [`14-3.4.0-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4.0-bookworm), [`14-3.4`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/14-3.4/bookworm/Dockerfile) | amd64 arm64 | bookworm | 14 | 3.4.0 |
| [`15-3.4-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4-bookworm), [`15-3.4.0-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4.0-bookworm), [`15-3.4`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4), [`latest`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=latest) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/15-3.4/bookworm/Dockerfile) | amd64 arm64 | bookworm | 15 | 3.4.0 |
<!-- bookworm_end  -->

### Debian - bullseye

- We use PostGIS, geos, proj, gdal, and sfcgal packages from the Debian repository.
  - In the Debian Bullseye repository, the versions are: geos=3.9, gdal=3.2, proj=7.2, and sfcgal=1.3.9.
- This version is easy to extend and has matured over time.
- PostgreSQL 11 is not compatible with PostGIS 3.4, so it remains on PostGIS 3.3. Please note that after November 9, 2023, PostgreSQL 11 will reach its [end-of-life (EOL)](https://www.postgresql.org/support/versioning/) and will no longer receive support.

<!-- bullseye_begin  -->
| `imresamu/postgis:` tags | Dockerfile | Arch | OS | Postgres | PostGIS |
| ---- | :-: | :-: | :-: | :-: | :-: |
| [`11-3.3-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=11-3.3-bullseye), [`11-3.3.4-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=11-3.3.4-bullseye) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/11-3.3/bullseye/Dockerfile) | amd64 | bullseye | 11 | 3.3.4 |
| [`12-3.4-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4-bullseye), [`12-3.4.0-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4.0-bullseye) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/12-3.4/bullseye/Dockerfile) | amd64 | bullseye | 12 | 3.4.0 |
| [`13-3.4-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4-bullseye), [`13-3.4.0-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4.0-bullseye) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/13-3.4/bullseye/Dockerfile) | amd64 | bullseye | 13 | 3.4.0 |
| [`14-3.4-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4-bullseye), [`14-3.4.0-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4.0-bullseye) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/14-3.4/bullseye/Dockerfile) | amd64 | bullseye | 14 | 3.4.0 |
| [`15-3.4-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4-bullseye), [`15-3.4.0-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4.0-bullseye) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/15-3.4/bullseye/Dockerfile) | amd64 | bullseye | 15 | 3.4.0 |
<!-- bullseye_end  -->

### Debian Geo Bundle ( experimental )

This repository provides Debian-based PostGIS Docker images enriched with additional geospatial packages such as [pgRouting](https://pgrouting.org/), [h3-pg]( https://github.com/zachasme/h3-pg), [pgsql-ogr-fdw](https://github.com/pramsey/pgsql-ogr-fdw), [MobilityDB](https://mobilitydb.com/), [PL/Python3](https://www.postgresql.org/docs/current/plpython.html), [pgPointcloud](https://pgpointcloud.github.io/pointcloud/), [pgVector](https://github.com/pgvector/pgvector), [TimeScaleDB](https://www.timescale.com/) and others.
These images serve as a comprehensive solution for various server side geospatial needs.
Please note that the included package list is subject to change as we continue to refine the bundle.

<!-- bundle_begin  -->
| `imresamu/postgis:` tags | Dockerfile | Arch | OS | Postgres | PostGIS |
| ---- | :-: | :-: | :-: | :-: | :-: |
| [`12-3.4-bundle-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4-bundle-bookworm), [`12-3.4.0-bundle-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4.0-bundle-bookworm), [`12-3.4-bundle`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4-bundle) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/12-3.4-bundle/bookworm/Dockerfile) | amd64 arm64 | bookworm | 12 | 3.4.0 |
| [`13-3.4-bundle-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4-bundle-bookworm), [`13-3.4.0-bundle-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4.0-bundle-bookworm), [`13-3.4-bundle`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4-bundle) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/13-3.4-bundle/bookworm/Dockerfile) | amd64 arm64 | bookworm | 13 | 3.4.0 |
| [`14-3.4-bundle-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4-bundle-bookworm), [`14-3.4.0-bundle-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4.0-bundle-bookworm), [`14-3.4-bundle`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4-bundle) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/14-3.4-bundle/bookworm/Dockerfile) | amd64 arm64 | bookworm | 14 | 3.4.0 |
| [`15-3.4-bundle-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4-bundle-bookworm), [`15-3.4.0-bundle-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4.0-bundle-bookworm), [`15-3.4-bundle`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4-bundle), [`bundle`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=bundle) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/15-3.4-bundle/bookworm/Dockerfile) | amd64 arm64 | bookworm | 15 | 3.4.0 |
<!-- bundle_end  -->

### Alpine based

- The base operating system is [Alpine Linux](https://alpinelinux.org/). It is designed to be small, simple, and secure, and it's based on [musl libc](https://musl.libc.org/).
- In the Alpine 3.18 version, the package versions are: geos=3.11, gdal=3.6, proj=9.2, and sfcgal=1.4.
- PostGIS is compiled from source, making it a bit more challenging to extend.
- PostgreSQL 11 is not compatible with PostGIS 3.4, so it remains on PostGIS 3.3. Please note that after November 9, 2023, PostgreSQL 11 will reach its [end-of-life (EOL)](https://www.postgresql.org/support/versioning/) and will no longer receive support.

<!-- alpine3.18_begin  -->
| `imresamu/postgis:` tags | Dockerfile | Arch | OS | Postgres | PostGIS |
| ---- | :-: | :-: | :-: | :-: | :-: |
| [`11-3.3-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=11-3.3-alpine3.18), [`11-3.3.4-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=11-3.3.4-alpine3.18), [`11-3.3-alpine`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=11-3.3-alpine) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/11-3.3/alpine3.18/Dockerfile) | amd64 | alpine3.18 | 11 | 3.3.4 |
| [`12-3.4-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4-alpine3.18), [`12-3.4.0-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4.0-alpine3.18), [`12-3.4-alpine`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=12-3.4-alpine) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/12-3.4/alpine3.18/Dockerfile) | amd64 | alpine3.18 | 12 | 3.4.0 |
| [`13-3.4-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4-alpine3.18), [`13-3.4.0-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4.0-alpine3.18), [`13-3.4-alpine`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=13-3.4-alpine) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/13-3.4/alpine3.18/Dockerfile) | amd64 | alpine3.18 | 13 | 3.4.0 |
| [`14-3.4-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4-alpine3.18), [`14-3.4.0-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4.0-alpine3.18), [`14-3.4-alpine`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-3.4-alpine) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/14-3.4/alpine3.18/Dockerfile) | amd64 | alpine3.18 | 14 | 3.4.0 |
| [`15-3.4-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4-alpine3.18), [`15-3.4.0-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4.0-alpine3.18), [`15-3.4-alpine`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-3.4-alpine), [`alpine`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=alpine) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/15-3.4/alpine3.18/Dockerfile) | amd64 | alpine3.18 | 15 | 3.4.0 |
<!-- alpine3.18_end  -->

### Test images

- We provide alpha, beta, release candidate (rc), and development (identified as ~master) versions.
- The template for the `*-master` images is updated manually, which might lead to a delay of a few weeks sometimes.
- The ~master SFCGAL version is 1.4 or higher. The cgal version is locked on the [5.6.x-branch](https://github.com/CGAL/cgal/tree/5.6.x-branch).

<!-- test_begin  -->
| `imresamu/postgis:` tags | Dockerfile | Arch | OS | Postgres | PostGIS |
| ---- | :-: | :-: | :-: | :-: | :-: |
| [`14-master-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-master-bookworm), [`14-master`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=14-master) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/14-master/bookworm/Dockerfile) | amd64 | bookworm | 14 | development: postgis, geos, proj, gdal |
| [`15-master-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-master-bookworm), [`15-master`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=15-master) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/15-master/bookworm/Dockerfile) | amd64 | bookworm | 15 | development: postgis, geos, proj, gdal |
| [`16beta3-3.4-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-3.4-alpine3.18), [`16beta3-3.4.0-alpine3.18`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-3.4.0-alpine3.18), [`16beta3-3.4-alpine`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-3.4-alpine) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/16-3.4/alpine3.18/Dockerfile) | amd64 | alpine3.18 | 16beta3 | 3.4.0 |
| [`16beta3-3.4-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-3.4-bookworm), [`16beta3-3.4.0-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-3.4.0-bookworm), [`16beta3-3.4`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-3.4) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/16-3.4/bookworm/Dockerfile) | amd64 arm64 | bookworm | 16beta3 | 3.4.0 |
| [`16beta3-3.4-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-3.4-bullseye), [`16beta3-3.4.0-bullseye`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-3.4.0-bullseye) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/16-3.4/bullseye/Dockerfile) | amd64 | bullseye | 16beta3 | 3.4.0 |
| [`16beta3-master-bookworm`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-master-bookworm), [`16beta3-master`](https://registry.hub.docker.com/r/postgis/postgis/tags?page=1&name=16beta3-master) | [Dockerfile](https://github.com/postgis/docker-postgis/blob/master/16-master/bookworm/Dockerfile) | amd64 | bookworm | 16beta3 | development: postgis, geos, proj, gdal |
<!-- test_end  -->

## Usage

In order to run a basic container capable of serving a PostGIS-enabled database, start a container as follows:

    docker run --name some-postgis -e POSTGRES_PASSWORD=mysecretpassword -d postgis/postgis

For more detailed instructions about how to start and control your Postgres container, see the documentation for the `postgres` image [here](https://registry.hub.docker.com/_/postgres/).

Once you have started a database container, you can then connect to the database either directly on the running container:

    docker exec -ti some-postgis psql -U postgres

... or starting a new container to run as a client. In this case you can use a user-defined network to link both containers:

    docker network create some-network

    # Server container
    docker run --name some-postgis --network some-network -e POSTGRES_PASSWORD=mysecretpassword -d postgis/postgis

    # Client container
    docker run -it --rm --network some-network postgis/postgis psql -h some-postgis -U postgres

Check the documentation on the [`postgres` image](https://registry.hub.docker.com/_/postgres/) and [Docker networking](https://docs.docker.com/network/) for more details and alternatives on connecting different containers.

See [the PostGIS documentation](http://postgis.net/docs/postgis_installation.html#create_new_db_extensions) for more details on your options for creating and using a spatially-enabled database.

## Supported Environment Variables:

Since the docker-postgis repository is an extension of the official Docker PostgreSQL repository, all environment variables supported there are also supported here:

- `POSTGRES_PASSWORD`
- `POSTGRES_USER`
- `POSTGRES_DB`
- `POSTGRES_INITDB_ARGS`
- `POSTGRES_INITDB_WALDIR`
- `POSTGRES_HOST_AUTH_METHOD`
- `PGDATA`

Read more:  https://github.com/docker-library/docs/blob/master/postgres/README.md

Warning: **the Docker specific variables will only have an effect if you start the container with a data directory that is empty;** any pre-existing database will be left untouched on container startup.

It's important to note that the environment variables for the Docker image are different from those of the [libpq — C Library](https://www.postgresql.org/docs/current/libpq-envars.html)  (`PGDATABASE`,`PGUSER`,`PGPASSWORD` )


## Troubleshooting tips:

Troubleshooting can often be challenging. It's important to know that the docker-postgis repository is an extension of the official Docker PostgreSQL repository. Therefore, if you encounter any issues, it's worth testing whether the problem can be reproduced with the [official PostgreSQL Docker images](https://hub.docker.com/_/postgres). If so, it's recommended to search for solutions based on this. The following websites are suggested:

- Upstream docker postgres repo: https://github.com/docker-library/postgres
  - search for the open or closed issues !
- Docker Community Forums: https://forums.docker.com
- Docker Community Slack: https://dockr.ly/slack
- Stack Overflow: https://stackoverflow.com/questions/tagged/docker+postgresql

If your problem is Postgis related:

- Stack Overflow : docker + postgis https://stackoverflow.com/questions/tagged/docker+postgis
- Postgis issue tracker: https://trac.osgeo.org/postgis/report

And if you don't have a postgres docker experience - read this blog post:

- https://www.docker.com/blog/how-to-use-the-postgres-docker-official-image/


## Security

It's crucial to be aware that in a cloud environment, with default settings, these images are vulnerable, and there's a high risk of cryptominer infection if the ports are left open. ( [Read More](https://github.com/docker-library/postgres/issues/770#issuecomment-704460980) )

- Note that ports which are not bound to the host (i.e., `-p 5432:5432` instead of `-p 127.0.0.1:5432:5432`) will be accessible from the outside. This also applies if you configured UFW to block this specific port, as Docker manages its own iptables rules. ( [Read More](https://docs.docker.com/network/iptables/) )

Recomendations:

- You can add options for using SSL ( [see postgres example](https://github.com/docker-library/postgres/issues/989#issuecomment-1222648067) )
  - `-c ssl=on -c ssl_cert_file=/var/lib/postgresql/server.crt -c ssl_key_file=/var/lib/postgresql/server.key`
- Or you can use [SSH Tunnels](https://www.postgresql.org/docs/15/ssh-tunnels.html) with `-p 127.0.0.1:5432:5432`

## Known Issues / Errors

When You encouter errors due to PostGIS update `OperationalError: could not access file "$libdir/postgis-X.X`, run:

`docker exec some-postgis update-postgis.sh`

It will update to Your newest PostGIS. Update is idempotent, so it won't hurt when You run it more than once, You will get notification like:

```
Updating PostGIS extensions template_postgis to X.X.X
NOTICE:  version "X.X.X" of extension "postgis" is already installed
NOTICE:  version "X.X.X" of extension "postgis_topology" is already installed
NOTICE:  version "X.X.X" of extension "postgis_tiger_geocoder" is already installed
ALTER EXTENSION
Updating PostGIS extensions docker to X.X.X
NOTICE:  version "X.X.X" of extension "postgis" is already installed
NOTICE:  version "X.X.X" of extension "postgis_topology" is already installed
NOTICE:  version "X.X.X" of extension "postgis_tiger_geocoder" is already installed
ALTER EXTENSION
```

