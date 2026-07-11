# renovate: datasource=docker depName=hansohn/terraform
ARG TERRAFORM_VERSION=1.15.7


# builder
FROM hansohn/terraform:${TERRAFORM_VERSION} AS builder
ARG DEBIAN_FRONTEND=noninteractive
# renovate: datasource=github-releases depName=digitalocean/doctl extractVersion=^v(?<version>.+)$
ARG DOCTL_VERSION=1.163.0
ENV CURL='curl -fsSL'
ENV CACHE_DIR='/var/cache/github-api'
COPY scripts/resolve-version.sh /opt/build/resolve-version
RUN apt-get update && apt-get install --no-install-recommends -y \
      ca-certificates \
      curl \
      jq \
      unzip \
  && mkdir -p ${CACHE_DIR} \
  && rm -rf /var/lib/apt/lists/*

# doctl
# The release archive is checksum-verified against the signed checksums file
# published alongside it, so the version is pinned and verified here rather than
# trusting whatever the download URL happens to serve.
RUN --mount=type=cache,target=/var/cache/github-api \
    --mount=type=cache,target=/var/cache/downloads \
    /bin/bash -c 'set -e; \
  DOCTL_VERSION=$(/opt/build/resolve-version doctl "${DOCTL_VERSION}"); \
  case "$(uname -m)" in \
    x86_64) ARCH=amd64 ;; \
    aarch64) ARCH=arm64 ;; \
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
  esac; \
  ARCHIVE="doctl-${DOCTL_VERSION}-linux-${ARCH}.tar.gz"; \
  if [[ ! -f "/var/cache/downloads/doctl-${DOCTL_VERSION}-${ARCH}.tar.gz" ]]; then \
  ${CURL} https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/${ARCHIVE} -o /var/cache/downloads/doctl-${DOCTL_VERSION}-${ARCH}.tar.gz; \
  fi; \
  if [[ ! -f "/var/cache/downloads/doctl-${DOCTL_VERSION}_checksums.sha256" ]]; then \
  ${CURL} https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-checksums.sha256 -o /var/cache/downloads/doctl-${DOCTL_VERSION}_checksums.sha256; \
  fi; \
  EXPECTED_SHA=$(grep " ${ARCHIVE}\$" /var/cache/downloads/doctl-${DOCTL_VERSION}_checksums.sha256 | cut -d" " -f1); \
  ACTUAL_SHA=$(sha256sum /var/cache/downloads/doctl-${DOCTL_VERSION}-${ARCH}.tar.gz | cut -d" " -f1); \
  if [[ -z "${EXPECTED_SHA}" ]] || [[ "${EXPECTED_SHA}" != "${ACTUAL_SHA}" ]]; then \
  echo "Checksum verification failed for ${ARCHIVE}" >&2; exit 1; \
  fi; \
  tar -xzf /var/cache/downloads/doctl-${DOCTL_VERSION}-${ARCH}.tar.gz -C /usr/local/bin \
  && chown root:root /usr/local/bin/doctl \
  && chmod +x /usr/local/bin/doctl \
  && doctl version'


# main
FROM hansohn/terraform:${TERRAFORM_VERSION} AS main
ARG DEBIAN_FRONTEND=noninteractive
# doctl ships shell completion; bash-completion wires it into interactive shells.
RUN apt-get update && apt-get install --no-install-recommends -y \
      bash-completion \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/bin/doctl /usr/local/bin/doctl
RUN printf '\nif [ -f /etc/profile.d/bash_completion.sh ]; then . /etc/profile.d/bash_completion.sh; fi\nsource <(doctl completion bash)\n' >> /root/.bashrc \
  && doctl version \
  && terraform --version

ENTRYPOINT []
