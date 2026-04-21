# syntax=docker/dockerfile:1
#
# Hayroll evaluation image
#
# Build:
#   ./build-docker.bash
#
# Run:
#   docker run -it hayroll-eval

FROM ubuntu:24.04

ARG RUST_VERSION=1.92.0

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/root/.cargo/bin:/root/.local/bin:${PATH}" \
    CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake ninja-build pkg-config python3 python3-pip wget curl ca-certificates git unzip \
      autoconf automake libtool bear \
      sudo vim nano less tree jq \
    && rm -rf /var/lib/apt/lists/*

# Rust stable and nightly toolchains
# Nightly toolchain required by Hayroll-translated code
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain ${RUST_VERSION} --no-modify-path
RUN rustup toolchain install nightly-2023-04-15

# Copy repo, then run setup: builds Hayroll and downloads all three benchmarks
WORKDIR /opt/hayroll-eval
COPY . .
RUN ./setup.bash

ENV PATH="/opt/hayroll-eval/Hayroll:${PATH}"

CMD ["/bin/bash"]
