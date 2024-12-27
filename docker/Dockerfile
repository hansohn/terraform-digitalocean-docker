ARG TERRAFORM_VERSION=latest


# builder
FROM hansohn/terraform:${TERRAFORM_VERSION} AS builder
ARG DOCTL_VERSION=latest
COPY dotfiles/. /root/
ENV CURL='curl -fsSL --netrc-optional'
RUN apt-get update && apt-get install --no-install-recommends -y \
      bash \
      ca-certificates \
      curl \
      jq \
      libc6 \
      unzip

# doctl
RUN /bin/bash -c 'ARCH=$(uname -m) && if [[ "$ARCH" =~ ^(arm|aarch).* ]]; then ARCH="arm64"; elif [[ "$ARCH" =~ ^x86_64.* ]]; then ARCH="amd64"; fi \
      && if [[ "${DOCTL_VERSION}" == "latest" ]]; then DOCTL_VERSION=$(${CURL} "https://api.github.com/repos/digitalocean/doctl/releases/latest" | jq -r .tag_name | sed -e "s:^v::"); fi \
      && ${CURL} https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-${ARCH}.tar.gz -o doctl-${DOCTL_VERSION}.tar.gz \
      && tar -xzf doctl-${DOCTL_VERSION}.tar.gz \
      && mv doctl /usr/local/bin/ \
      && chown root:root /usr/local/bin/doctl \
      && chmod +x /usr/local/bin/doctl \
      && doctl version'


# main
FROM hansohn/terraform:${TERRAFORM_VERSION} AS main
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends -y \
      bash \
      bash-completion \
      curl \
      ca-certificates \
      git \
      jq \
      unzip \
      vim \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*
COPY --from=builder /root/.terraform.d/. /root/.terraform.d/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
RUN /bin/bash -c 'terraform --version'
RUN echo '\n\
if [ -f /etc/profile.d/bash_completion.sh ]; then . /etc/profile.d/bash_completion.sh; fi\n\
. <(doctl completion "${SHELL##*/}")' >> /root/.bashrc

ENTRYPOINT []
