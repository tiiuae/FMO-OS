# SPDX-FileCopyrightText: 2022-2024 TII (SSRC) and the Ghaf contributors
#
# SPDX-License-Identifier: Apache-2.0

# Container image that runs your code
FROM ubuntu:22.04

ENV TZ=Europe/Helsinki

RUN apt-get update && apt-get -y install curl xz-utils git

# Install nixos
COPY install_nix.sh /install_nix.sh
RUN /install_nix.sh

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

