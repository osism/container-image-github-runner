FROM ubuntu:20.04
ARG VERSION=2.283.1

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        git \
        gnupg-agent \
        gosu \
        jq \
        libc6-dev \
        libc++-dev \
        libffi-dev \
        libssl-dev \
        libyaml-dev \
        lsb-release \
        make \
        openssh-client \
        patch \
        python3-dev \
        python3-pip \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        rsync \
        software-properties-common \
        sudo \
        tini \
        uidmap \
        wget \
    && apt-get clean -y \
    && rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# NOTE: Buildah/Podman not yet available in Ubuntu 20.04.
#
#       Use of Ubuntu > 20.04 not yet possible as the official
#       runners from GitHub are currently on Ubuntu 20.04.

RUN echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list \
    && wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_20.04/Release.key -O /tmp/Release.key \
    && apt-key add - < /tmp/Release.key \
    && rm -f /tmp/Release.key \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        buildah \
        fuse-overlayfs \
        podman \
    && apt-get clean -y \
    && rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -m github \
    && usermod -aG sudo github \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER github
WORKDIR /home/github
COPY --chown=github:github files/entrypoint.sh ./entrypoint.sh
COPY --chown=github:github files/get_token.py ./get_token.py
COPY --chown=github:github files/requirements.txt ./requirements.txt

RUN python3 -m pip install -r requirements.txt

RUN curl -LO "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-x64-${VERSION}.tar.gz" \
    && tar xzf ./*.tar.gz \
    && rm ./*.tar.gz

USER root
RUN mkdir -p /opt/hostedtoolcache \
    && chown -R github: /opt/hostedtoolcache \
    && ./bin/installdependencies.sh

USER github

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache

EXPOSE 443
ENTRYPOINT ["/usr/bin/tini", "--", "/home/github/entrypoint.sh"]
