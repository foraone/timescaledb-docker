ARG PG_VERSION_TAG
ARG ARCH
FROM foraone/timescaledb:1.2.2-${PG_VERSION_TAG}-${ARCH}
MAINTAINER Sergii Savchenko https://fora.one

ARG GDAL_VERSION=v2.4.0
ARG LIBKML_VERSION=1.3.0
ARG GEOS_VERSION=3.7.1
ARG POSTGIS_VERSION
ENV POSTGIS_VERSION ${POSTGIS_VERSION:-2.5.1}

RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps \
                openssl ca-certificates \
                build-base cmake musl-dev linux-headers \
                # for libkml compilation
                zlib-dev minizip-dev expat-dev uriparser-dev boost-dev \
    && apk add --no-cache --virtual .crypto-rundeps \
                --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
                libressl2.7-libcrypto \
                libcrypto1.1 \
    && apk add --no-cache --virtual .postgis-deps --repository http://nl.alpinelinux.org/alpine/edge/testing \
        proj4 \
        protobuf-c \
    && apk add --no-cache --virtual .build-deps --repository http://nl.alpinelinux.org/alpine/edge/testing \
        postgresql-dev \
        perl \
        file \
        python \
        python-dev \
        py-pip \
        libxml2-dev \
        proj4-dev \
        protobuf-c-dev \
        json-c-dev \
        gcc g++ \
        make \
    && cd /tmp \
    && wget -O libkml.tar.gz "https://github.com/libkml/libkml/archive/${LIBKML_VERSION}.tar.gz" \
    && tar --extract --file libkml.tar.gz \
    && cd libkml-${LIBKML_VERSION} && mkdir build \
    && cd build \
    && cmake .. \
    && make \
    && make install \
    && cd /tmp \
    && wget -O gdal.tar.gz "https://github.com/OSGeo/gdal/archive/${GDAL_VERSION}.tar.gz" \
    && tar --extract --file gdal.tar.gz --strip-components 1 \
    && cd gdal \
    && ./configure --prefix=/usr \
        --with-libkml \
        --without-bsb \
        --without-dwgdirect \
        --without-ecw \
        --without-fme \
        --without-gnm \
        --without-grass \
        --without-grib \
        --without-hdf4 \
        --without-hdf5 \
        --without-idb \
        --without-ingress \
        --without-jasper \
        --without-mrf \
        --without-mrsid \
        --without-netcdf \
        --without-pcdisk \
        --without-pcraster \
        --without-webp \
    && make \
    && make install \
    # gdal python bindings
    && pip install gdal --no-cache-dir \
    && cd /tmp \
    && rm -rf build \
    #rm -rf /var/cache/apk/* && \
    #rm -rf /usr/lib/python2.7 \
    && cd /tmp \
    && wget http://download.osgeo.org/geos/geos-3.7.1.tar.bz2 \
    && tar xjf geos*bz2 \
    && cd geos* \
    && ./configure --enable-python \
    && make -j 8 \
    && make install \
    && cd .. \
    #------------ posrgis
    && cd /tmp \
    && wget http://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz -O - | tar -xz \
    && chown root:root -R postgis-${POSTGIS_VERSION} \
    && cd /tmp/postgis-${POSTGIS_VERSION} \
    && ./configure \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis/Makefile \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis_topology/Makefile \
    && make -s \
    && make -s install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && cd / \
    && apk del .fetch-deps .build-deps \
    && rm -rf /tmp


