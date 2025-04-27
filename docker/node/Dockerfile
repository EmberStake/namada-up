FROM rust:1.85.1-bookworm AS genesis-builder
USER root
WORKDIR /__w/namada
# The version should be matching the version set above
RUN rustup toolchain install 1.85.1 --profile minimal
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

FROM golang:1.23-bookworm AS cometbft-builder
WORKDIR /app

RUN git clone -b v0.37.15 https://github.com/cometbft/cometbft.git
WORKDIR cometbft
RUN make build

# TODO : remove this stage in the next version
FROM rust:1.85.1-bookworm AS masp-migration-builder
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    gcc-multilib \
    protobuf-compiler \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LO https://golang.org/dl/go1.22.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz && \
    rm go1.22.0.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:$PATH"
WORKDIR /app
RUN git clone https://github.com/heliaxdev/migrate-masp-events
WORKDIR migrate-masp-events
RUN make CGO_LDFLAGS="-lm -ldl"

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
# TODO: remove this in the next version
COPY --chown=pilot:pilot --from=masp-migration-builder /app/migrate-masp-events/migrate-masp-events /usr/local/bin

# Set up bash completion for Namada
RUN namada complete --shell bash > /usr/share/bash-completion/completions/namada.bash
RUN echo 'if ! shopt -oq posix; then\n  if [ -f /usr/share/bash-completion/bash_completion ]; then\n    . /usr/share/bash-completion/bash_completion\n  fi\nfi' >> /etc/bash.bashrc

USER pilot
RUN mkdir /home/pilot/.masp-params
WORKDIR /home/pilot/.local/share/namada

ENTRYPOINT ["/usr/local/bin/namada"]
CMD ["--help"]