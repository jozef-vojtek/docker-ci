FROM debian:buster-slim as base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      zip unzip \
      curl \
      wget \
      jq \
      git && \
    rm -rf /var/lib/apt/lists/* && \
    update-ca-certificates
    
# Docker
FROM base as docker
ENV DOCKER_VERSION=19.03.1
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
  && mv docker-${DOCKER_VERSION}.tgz docker.tgz \
  && tar xzvf docker.tgz \
  && mv docker/docker /usr/local/bin \
  && rm -r docker docker.tgz
  
# Docker Compose
FROM base as docker_compose
ENV DOCKER_COMPOSE_VERSION=1.24.1
RUN curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

# Docker Machine
FROM base as docker_machine
ENV DOCKER_MACHINE_VERSION=v0.16.1
RUN base=https://github.com/docker/machine/releases/download/$DOCKER_MACHINE_VERSION && \
    curl -L $base/docker-machine-$(uname -s)-$(uname -m) > /tmp/docker-machine && \
    install /tmp/docker-machine /usr/local/bin/docker-machine
    
# kubectl
FROM base as kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin
    
# Final Image
FROM base
COPY --from=docker /usr/local/bin/docker /usr/local/bin
COPY --from=docker_compose /usr/local/bin/docker-compose /usr/local/bin
COPY --from=docker_machine /usr/local/bin/docker-machine /usr/local/bin
COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin
