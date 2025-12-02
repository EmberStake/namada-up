FROM rust:1.85.1-bookworm AS genesis-builder
USER root
WORKDIR /__w/namada
# The version should be matching the version set above
RUN rustup toolchain install 1.85.1 --profile minimal
RUN rustup target add wasm32-unknown-unknown

RUN apt-get update && apt-get install -y \
    build-essential \
    clang-14 \
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

FROM golang:1.23-bookworm AS cometbft-builder
WORKDIR /app

RUN git clone -b v0.37.16 https://github.com/cometbft/cometbft.git
WORKDIR cometbft
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
    bash-completion \
    && apt-get clean


# Create oeprator user
RUN useradd -m pilot

COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/wasm/*.wasm /__w/namada/namada/wasm/*.json /home/pilot/wasm/

COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/target/release/namada /usr/local/bin
COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/target/release/namadan /usr/local/bin
COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/target/release/namadaw /usr/local/bin
COPY --chown=pilot:pilot --from=genesis-builder /__w/namada/namada/target/release/namadac /usr/local/bin
COPY --chown=pilot:pilot --from=cometbft-builder /app/cometbft/build/cometbft /usr/local/bin

# Set up bash completion for Namada
RUN namada complete --shell bash > /usr/share/bash-completion/completions/namada.bash
RUN echo 'if ! shopt -oq posix; then\n  if [ -f /usr/share/bash-completion/bash_completion ]; then\n    . /usr/share/bash-completion/bash_completion\n  fi\nfi' >> /etc/bash.bashrc

USER pilot
RUN mkdir /home/pilot/.masp-params
WORKDIR /home/pilot/.local/share/namada

ENTRYPOINT ["/usr/local/bin/namada"]
CMD ["--help"]