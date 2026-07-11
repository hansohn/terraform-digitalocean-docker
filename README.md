<div align="center">
  <h3>terraform-digitalocean-docker</h3>
  <p>Terraform DigitalOcean Docker image</p>
  <p>
    <!-- Build Status -->
    <a href="https://github.com/hansohn/terraform-digitalocean-docker/actions/workflows/docker.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/hansohn/terraform-digitalocean-docker/docker.yml?style=for-the-badge">
    </a>
    <!-- Github Tag -->
    <a href="https://gitHub.com/hansohn/terraform-digitalocean-docker/tags/">
      <img src="https://img.shields.io/github/tag/hansohn/terraform-digitalocean-docker.svg?style=for-the-badge">
    </a>
    <!-- Docker Pulls -->
    <a href="https://hub.docker.com/r/hansohn/terraform-digitalocean">
      <img src="https://img.shields.io/docker/pulls/hansohn/terraform-digitalocean.svg?style=for-the-badge">
    </a>
    <!-- Docker Image Size -->
    <a href="https://hub.docker.com/r/hansohn/terraform-digitalocean">
      <img src="https://img.shields.io/docker/image-size/hansohn/terraform-digitalocean/latest.svg?style=for-the-badge">
    </a>
    <!-- License -->
    <a href="https://github.com/hansohn/terraform-digitalocean-docker/blob/main/LICENSE">
      <img src="https://img.shields.io/github/license/hansohn/terraform-digitalocean-docker.svg?style=for-the-badge">
    </a>
  </p>
</div>

## Table of Contents

- [Description](#description)
- [What's Included](#whats-included)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Tags](#tags)
- [Platform Support](#platform-support)
- [Usage](#usage)
- [Examples](#examples)
- [Customization](#customization)
- [Build & Refresh Schedule](#build--refresh-schedule)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

## Description

Welcome to my Terraform DigitalOcean Docker repo. This image extends the
[terraform](https://github.com/hansohn/terraform-docker) image with
DigitalOcean-specific tooling, built with Terraform development and CI/CD in
mind. It bundles the DigitalOcean CLI (`doctl`) on top of the base Terraform
toolchain. Tool versions are pinned in the Dockerfile and kept current through
dependency-update PRs; the image is rebuilt and published to Docker Hub weekly
(Mondays) to pick up base-image security patches.

## What's Included

This image builds on [hansohn/terraform](https://hub.docker.com/r/hansohn/terraform),
which provides:

- [terraform](https://github.com/hashicorp/terraform): Software tool that enables you to safely and predictably create, change, and improve infrastructure
- [terragrunt](https://github.com/gruntwork-io/terragrunt): A thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules
- [terraform-docs](https://github.com/terraform-docs/terraform-docs): Generate documentation from Terraform modules in various output formats
- [tflint](https://github.com/terraform-linters/tflint): A Pluggable Terraform Linter
- [trivy](https://github.com/aquasecurity/trivy): Security scanner for your Terraform code

On top of that base, this image adds:

- [doctl](https://docs.digitalocean.com/reference/doctl/): The official DigitalOcean command line interface (CLI), with bash completion pre-configured

## Prerequisites

- Docker 20.10 or later
- Docker Buildx with BuildKit (required for multi-platform builds and the
  build cache mounts the Dockerfile relies on)

## Quick Start

```bash
# Pull and run the latest version
docker pull hansohn/terraform-digitalocean:latest
docker run -it --rm hansohn/terraform-digitalocean:latest terraform version

# Run with your Terraform code mounted
docker run -it --rm -v $(pwd):/workspace -w /workspace hansohn/terraform-digitalocean:latest terraform plan
```

## Tags

Docker images are tagged based on the pinned version of Terraform they include
(inherited from the base image). A single Terraform version is published at a
time, and it receives the full set of tags below:

```
# tag formats (for a pinned Terraform version of e.g. 1.15.7)
hansohn/terraform-digitalocean:latest        the currently published release
hansohn/terraform-digitalocean:1             the 1.x.x line
hansohn/terraform-digitalocean:1.15          the 1.15.x line
hansohn/terraform-digitalocean:1.15.7        the exact version
```

For reproducibility, pin by digest (`hansohn/terraform-digitalocean@sha256:...`);
every image ships provenance attestations and an SBOM bound to that digest.

## Platform Support

This image supports multiple platforms:

- `linux/amd64` (x86_64)
- `linux/arm64` (ARM64/Apple Silicon)

Docker will automatically pull the correct architecture for your system.

## Usage

Published images can be run using the following syntax:

```bash
# run latest published version
docker run -it --rm hansohn/terraform-digitalocean:latest /bin/bash
```

Local images can be built and run using the following syntax:

```bash
# build and run local image
make
```

Additionally, a Makefile has been included in this repo to assist with common
development-related functions. I've included the following make targets for
convenience:

```
Available targets:

  clean                               Clean everything
  dev                                 Initialize development environment
  docker/build                        Docker build image
  docker/check                        Check if Docker daemon is running
  docker/clean                        Docker clean build images
  docker/lint                         Lint Dockerfile
  docker/push                         Docker push image
  docker/run                          Docker run image
  help                                Help screen
  help/all                            Display help for all targets
  help/short                          This help short screen
```

## Examples

### Initialize Terraform

```bash
docker run -it --rm -v $(pwd):/workspace -w /workspace \
  hansohn/terraform-digitalocean:latest terraform init
```

### Run the DigitalOcean CLI

```bash
docker run -it --rm -e DIGITALOCEAN_ACCESS_TOKEN \
  hansohn/terraform-digitalocean:latest doctl account get
```

### Generate Documentation

```bash
docker run -it --rm -v $(pwd):/docs -w /docs \
  hansohn/terraform-digitalocean:latest terraform-docs markdown . > README.md
```

### Run Security Scan

```bash
docker run -it --rm -v $(pwd):/src -w /src \
  hansohn/terraform-digitalocean:latest trivy config .
```

## Customization

### Utilities

Utility versions are pinned in the [Dockerfile](Dockerfile) and kept current
through automated dependency-update PRs. For a local build you can override any
of them on the command line to target a specific version:

- TERRAFORM_VERSION (selects the base `hansohn/terraform` image tag)
- DOCTL_VERSION

```bash
# build against a specific doctl version
DOCTL_VERSION=1.163.0 make docker/build
```

> **Note:** Builds require BuildKit (the default in modern Docker). The Dockerfile
> uses BuildKit cache mounts, so `DOCKER_BUILDKIT=0` is not supported.

## Build & Refresh Schedule

Images are automatically:

- **Built and linted** on every push (multi-platform, without publishing)
- **Published** when a version tag is pushed
- **Refreshed** every Monday at 7am UTC to pick up the latest base-image security patches

This ensures published images stay up-to-date with the latest base image security updates.

## Security

- Images include provenance attestations and SBOM (Software Bill of Materials)
- The `doctl` release archive is checksum-verified at build time
- Published images are scanned for vulnerabilities with Trivy
- Security vulnerabilities? See our [Security Policy](.github/SECURITY.md)

## Contributing

Contributions are welcome! Please see our [Contributing Guide](.github/CONTRIBUTING.md) for details.

- Report bugs via [Issues](https://github.com/hansohn/terraform-digitalocean-docker/issues)
- Request features via [Feature Requests](https://github.com/hansohn/terraform-digitalocean-docker/issues/new?template=feature-request.yml)
- Submit PRs following our [PR Template](.github/PULL_REQUEST_TEMPLATE.md)

## License

This project is licensed under the terms specified in [LICENSE](LICENSE).
