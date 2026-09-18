FROM mcr.microsoft.com/devcontainers/base:ubuntu26.04

USER root

#####
##  Setup

RUN apt-get update && apt-get install -y \
  curl \
  tar \
  unzip \
  ca-certificates \
  software-properties-common \
  gnupg \
  dos2unix \
  git-lfs \
  golang-go

#####
## Terraform

RUN TERRAFORM_VER=$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | sed -n 's/.*"current_version":"\([^"]*\)".*/\1/p') \
  && curl -fsSLo terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip" \
  && unzip terraform.zip \
  && mv terraform /usr/local/bin/ \
  && rm terraform.zip

#####
## Azure CLI

RUN curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash

#####
## Kubectl

RUN KUBECTL_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt) \
  && curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/amd64/kubectl" \
  && chmod +x /usr/local/bin/kubectl

#####
## Helm

RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

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
  && helm plugin install https://github.com/databus23/helm-diff

#####
## Ansible

RUN apt-get install -y ansible ansible-lint

#####
##  Cleanup

RUN apt-get clean && rm -rf /var/lib/apt/lists/*