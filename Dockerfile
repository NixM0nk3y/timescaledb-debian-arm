#
#
#

FROM debian:buster

LABEL maintainer="Nick Gregory <docker@openenterprise.co.uk>"

ARG TIMESCALEDB_VERSION="2.5.1"

# basic build infra
RUN apt-get -y update \
    && apt-get -y dist-upgrade \
    && apt-get -y install curl build-essential cmake sudo wget git-core autoconf automake pkg-config quilt \
    && apt-get -y install ruby ruby-dev rubygems \
    && gem install --no-document fpm

# package deps
RUN curl http://apt-openenterprise.s3-website.eu-west-2.amazonaws.com/openenterprise.pub | sudo apt-key add - \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" > /etc/apt/sources.list.d/postgres.list \
    && echo "deb http://deb.debian.org/debian buster-backports main" > /etc/apt/sources.list.d/buster-backports.list \
    && apt-get -y update \
    && apt-get -y install postgresql-server-dev-12 libssl-dev libkrb5-dev

# package build
RUN mkdir /src && cd /src \
    && git clone https://github.com/timescale/timescaledb.git \
    && cd timescaledb \
    && git checkout ${TIMESCALEDB_VERSION} \
    && ./bootstrap -DSEND_TELEMETRY_DEFAULT=OFF -DREGRESS_CHECKS=OFF \
    && cd build && make

# package install
RUN cd /src/timescaledb/build \
    && make DESTDIR=/install install \
    && fpm -s dir -t deb -C /install --name timescaledb-postgresql-12 --version ${TIMESCALEDB_VERSION} --iteration 1 --depends "libssl1.1 (>= 1.1.0)" --depends "postgresql-12 (>= 12.4)" \
       --description "An open-source time-series database based on PostgreSQL, as an extension. \
 An open-source time-series database optimized for fast ingest and complex queries. \
 Engineered up from PostgreSQL, packaged as an extension."
STOPSIGNAL SIGTERM
