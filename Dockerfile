FROM ghcr.io/flant/shell-operator:v1.5.1 as shell-operator
RUN \
  mkdir -p \
    /rootfs/frameworks/shell \
    /rootfs/usr/bin \
  && \
  cp \
    /usr/bin/jq \
    /rootfs/usr/bin \
  && \
  cp \
    /shell-operator \
    /shell_lib.sh \
    /rootfs \
  && \ 
  cp \
    /frameworks/shell/context.sh \
    /frameworks/shell/hook.sh \
    /rootfs/frameworks/shell

# Main image
FROM docker.io/library/debian:bookworm-20241016
ARG hooks=default
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
LABEL \
  org.opencontainers.image.source https://github.com/illallangi/controllers

RUN \
# Install packages
  apt-get update \
  && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates=20230311 \
    curl=7.88.1-10+deb12u8 \
    python3-pip=23.0.1+dfsg-1 \
  && \
  apt-get clean \
  && \
  rm -rf /var/lib/apt/lists/* \
  && \
# Install s6 overlay
  if [ "$(uname -m)" = "x86_64" ]; then \
    curl \
      https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64-installer \
      --location \
      --output /tmp/s6-overlay-installer \
      --silent \
  ; fi \
  && \
  if [ "$(uname -m)" = "aarch64" ]; then \
    curl \
      https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-aarch64-installer \
      --location \
      --output /tmp/s6-overlay-installer \
      --silent \
  ; fi \
  && \
  chmod +x \
    /tmp/s6-overlay-installer \
  && \
  /tmp/s6-overlay-installer / \
  && \
  rm /tmp/s6-overlay-installer \
  && \
# Install kubectl
  if [ "$(uname -m)" = "x86_64" ]; then \
    curl \
      https://dl.k8s.io/release/v1.30.3/bin/linux/amd64/kubectl \
      --location \
      --output /usr/bin/kubectl \
      --silent \
  ; fi \
  && \
  if [ "$(uname -m)" = "aarch64" ]; then \
    curl \
      https://dl.k8s.io/release/v1.30.3/bin/linux/arm64/kubectl \
      --location \
      --output /usr/bin/kubectl \
      --silent \
  ; fi \
  && \
  chmod +x \
    /usr/bin/kubectl \
  && \
# Make directories
  mkdir -p /hooks /usr/src/app

# Install shell-operator
COPY --from=shell-operator /rootfs /

# Set environment variables
ENV \
  IMAGE_ACTUAL=ghcr.io/actualbudget/actual-server:24.10.1 \
  IMAGE_BEETS=ghcr.io/linuxserver/beets:2.0.0-ls242 \
  IMAGE_CADDY=docker.io/library/caddy:2.8.4 \
  IMAGE_COPS=ghcr.io/linuxserver/cops:3.3.1-ls231 \
  IMAGE_DELUGE=ghcr.io/linuxserver/deluge:2.1.1 \
  IMAGE_ESPHOME=ghcr.io/esphome/esphome:2024.10.2 \
  IMAGE_FLIGHTRADAR24=ghcr.io/sdr-enthusiasts/docker-flightradar24:1.0.48-0_nohealthcheck \
  IMAGE_GATUS=docker.io/twinproduction/gatus:v5.11.0 \
  IMAGE_HOMEASSISTANT=ghcr.io/linuxserver/homeassistant:2024.10.4-ls41 \
  IMAGE_INITJINJA=ghcr.io/illallangi/init-jinja:v0.0.3 \
  IMAGE_K8SWAITFOR=ghcr.io/groundnuty/k8s-wait-for:v2.0 \
  IMAGE_KAVITA=ghcr.io/linuxserver/kavita:v0.8.2-ls44 \
  IMAGE_KEYCLOAK=docker.io/bitnami/keycloak:25.0.6 \
  IMAGE_MARIADB=docker.io/library/mariadb:11.4.2 \
  IMAGE_MASTODON=ghcr.io/linuxserver/mastodon:v4.2.10-ls97 \
  IMAGE_PIGALLERY=docker.io/bpatrik/pigallery2:latest \
  IMAGE_PLANEFENCE=ghcr.io/sdr-enthusiasts/docker-planefence:latest \
  IMAGE_PLANEWATCH=ghcr.io/plane-watch/docker-plane-watch:latest \
  IMAGE_PLEX=ghcr.io/linuxserver/plex:1.40.4 \
  IMAGE_PODFETCH=ghcr.io/samtv12345/podfetch:latest \
  IMAGE_POSTGRES=docker.io/library/postgres:16.3 \
  IMAGE_RADARR=ghcr.io/linuxserver/radarr:5.8.3.8933-ls230 \
  IMAGE_REDIS=docker.io/library/redis:7.2.5 \
  IMAGE_REGISTRY=docker.io/library/registry:2.8.3 \
  IMAGE_RESTIC=docker.io/mazzolino/restic:1.7.2 \
  IMAGE_RSYNC=ghcr.io/servercontainers/rsync:a3.20.2-r3.3.0 \
  IMAGE_SHIPXPLORER=ghcr.io/sdr-enthusiasts/shipxplorer:latest \
  IMAGE_SHLINK=ghcr.io/shlinkio/shlink:4.1.1 \
  IMAGE_SHLINKWEBCLIENT=ghcr.io/shlinkio/shlink-web-client:4.1.2 \
  IMAGE_SONARR=ghcr.io/linuxserver/sonarr:4.0.8.1874-ls248 \
  IMAGE_STASH=docker.io/stashapp/stash:v0.26.2 \
  IMAGE_TAILSCALE=ghcr.io/tailscale/tailscale:v1.70.0 \
  IMAGE_TANDOOR=docker.io/vabene1111/recipes:1.5.18 \
  IMAGE_TOOLBOX=ghcr.io/illallangi/toolbx:latest \
  IMAGE_ULTRAFEEDER=ghcr.io/sdr-enthusiasts/docker-adsb-ultrafeeder:latest \
  IMAGE_WEBTREES=ghcr.io/nathanvaughn/webtrees:2.1.20 \
  IMAGE_WORDPRESS=docker.io/library/wordpress:6.6.1-apache \
  S6_BEHAVIOUR_IF_STAGE2_FAILS=2
  
# Set command
CMD ["/init"]

# Install Python requirements
COPY rootfs/usr/src/app/requirements.txt /usr/src/app/requirements.txt
RUN python3 -m pip install --no-cache-dir --break-system-packages -r /usr/src/app/requirements.txt

# Copy rootfs
COPY rootfs /

# Copy hooks
COPY hooks/${hooks} /hooks

# Install Python package
RUN python3 -m pip install --no-cache-dir --break-system-packages  /usr/src/app
