FROM rust:1.81.0-bookworm AS genesis-builder
USER root
WORKDIR /__w/namada
# The version should be matching the version set above
RUN rustup toolchain install 1.81.0 --profile minimal
RUN rustup target add wasm32-unknown-unknown

RUN apt-get update && apt-get install -y \
    build-essential \
    clang-tools-14 \
    git \
    libssl-dev \
    pkg-config \
    protobuf-compiler \
    libudev-dev \
    && apt-get clean

# Download binaryen and extract wasm-opt
ADD https://github.com/WebAssembly/binaryen/releases/download/version_113/binaryen-version_113-x86_64-linux.tar.gz /tmp/binaryen.tar.gz
RUN tar -xf /tmp/binaryen.tar.gz
RUN mv binaryen-version_*/bin/wasm-opt /usr/local/bin

ARG NAMADA_TAG=main
RUN git clone -b ${NAMADA_TAG} https://github.com/anoma/namada.git
WORKDIR /__w/namada/namada

RUN make build-release
RUN make build-wasm-scripts

FROM golang:1.23-bookworm as tendermint-builder
WORKDIR /app

RUN git clone https://github.com/cometbft/cometbft.git
WORKDIR cometbft
RUN git checkout v0.37.11
RUN make build

FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    curl \
    nano \
    jq \
    dnsutils \
    wget \
    unzip \
    lz4 \
    aria2 \
    pv \
    git \
    gawk \
    iputils-ping \
    iproute2 \
    && apt-get clean

# Create oeprator user
RUN useradd -m pilot
USER pilot

COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/wasm/*.wasm /__w/namada/namada/wasm/*.json /home/pilot/wasm/

COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/target/release/namada /usr/local/bin
COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/target/release/namadan /usr/local/bin
COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/target/release/namadaw /usr/local/bin
COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/target/release/namadac /usr/local/bin
COPY --chown=pilot:pilot --from=tendermint-builder /app/cometbft/build/cometbft /usr/local/bin
COPY --chown=pilot:pilot --chmod=700 docker/node/entrypoint.sh /opt/entrypoint.sh

RUN mkdir /home/pilot/.masp-params
WORKDIR /home/pilot/.local/share/namada

# This entrypoint is a workaround to this issue https://github.com/anoma/namada/issues/3953
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["--help"]