FROM mcr.microsoft.com/devcontainers/base:ubuntu26.04

USER root

#####
##  Setup

RUN apt-get update && apt-get install -y \
  curl \
  tar \
  ca-certificates \
  software-properties-common \
  gnupg \
  dos2unix \
  git-lfs

#####
##  CNPG

RUN curl -sSfL "https://github.com/cloudnative-pg/cloudnative-pg/raw/main/hack/install-cnpg-plugin.sh" | sudo sh -s -- -b /usr/local/bin

#####
##  HCloud

RUN curl -sSLO https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz \
  && sudo tar -C /usr/local/bin --no-same-owner -xzf hcloud-linux-amd64.tar.gz hcloud \
  && rm hcloud-linux-amd64.tar.gz

#####
## Helmfile

RUN HELMFILE_VER=$(curl -s https://api.github.com/repos/helmfile/helmfile/releases/latest | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/') \
  && curl -L -o helmfile.tar.gz "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VER}/helmfile_${HELMFILE_VER}_linux_amd64.tar.gz" \
  && tar -zxvf helmfile.tar.gz helmfile \
  && mv helmfile /usr/local/bin/ \
  && rm helmfile.tar.gz \
  && helm plugin install https://github.com/databus23/helm-diff --verify=false

#####
##  Cleanup

RUN apt-get clean && rm -rf /var/lib/apt/lists/*