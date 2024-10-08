ARG MUMBLE_UID=10000
ARG MUMBLE_GID=10000

ARG MUMBLE_VERSION=latest
ARG MUMBLE_BUILD_NUMBER=""
ARG MUMBLE_CMAKE_ARGS=""

FROM ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
        libcap2 \
        libzeroc-ice3.7 \
        '^libprotobuf[0-9]+$' \
        libavahi-compat-libdnssd1 \
        libqt6core6 \
        libqt6network6 \
        libqt6sql6 \
        libqt6sql6-mysql \
        libqt6sql6-psql \
        libqt6sql6-sqlite \
        libqt6xml6 \
        libqt6dbus6 \
        ca-certificates \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*



FROM base AS build
ARG MUMBLE_VERSION
ARG MUMBLE_BUILD_NUMBER
ARG MUMBLE_CMAKE_ARGS

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
        git \
        cmake \
        build-essential \
        pkg-config \
        libssl-dev \
        qt6-base-dev \
        qt6-tools-dev \
        libboost-dev \
        libprotobuf-dev \
        protobuf-compiler \
        libprotoc-dev \
        libcap-dev \
        libxi-dev \
        libavahi-compat-libdnssd-dev \
        libzeroc-ice-dev \
        python3 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ADD ./scripts/* /mumble/scripts/
WORKDIR /mumble/repo

ENV MUMBLE_VERSION=${MUMBLE_VERSION} \
    MUMBLE_BUILD_NUMBER=${MUMBLE_BUILD_NUMBER} \
    MUMBLE_CMAKE_ARGS=${MUMBLE_CMAKE_ARGS}

# Clone the repo, build it and finally copy the default server ini file. Since this file may be at different locations and Docker
# doesn't support conditional copies, we have to ensure that regardless of where the file is located in the repo, it will end
# up at a unique path in our build container to be copied further down.
RUN /mumble/scripts/clone.sh \
 && /mumble/scripts/build.sh \
 && /mumble/scripts/copy_one_of.sh ./scripts/murmur.ini ./auxiliary_files/mumble-server.ini default_config.ini


FROM base AS final
ARG MUMBLE_UID
ARG MUMBLE_GID

COPY entrypoint.sh /entrypoint.sh
COPY --from=build /mumble/repo/build/mumble-server /usr/bin/mumble-server
COPY --from=build /mumble/repo/default_config.ini /etc/mumble/bare_config.ini

RUN groupadd --gid $MUMBLE_GID --system mumble \
 && useradd --uid $MUMBLE_UID --gid $MUMBLE_GID --system mumble \
 && mkdir -p /data \
 && chown -R mumble:mumble /data \
 && chown -R mumble:mumble /etc/mumble

USER mumble
EXPOSE 64738/tcp 64738/udp
VOLUME ["/data"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/mumble-server", "-fg"]
