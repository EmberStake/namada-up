# Stage 1: Build environment
FROM oven/bun:1-debian AS builder

# Install Rust and cargo
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    git \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Install Rust using rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup target add wasm32-unknown-unknown

# Set working directory
WORKDIR /app
ARG NAMADA_EXPORTER_TAG
# Clone repository
RUN git clone -b $NAMADA_EXPORTER_TAG https://github.com/MELLIFERA-Labs/namada-exporter.git .

# Install and build shared dependencies
WORKDIR /app/shared
RUN bun install
RUN bun run prepublish

# Install exporter dependencies
WORKDIR /app/exporter
RUN bun install --production --frozen-lockfile

# Build the binary
WORKDIR /app
RUN bun build ./exporter/src/index.ts --compile --outfile namada-exporter

# Stage 2: Runtime environment
FROM debian:bookworm-slim

# Install required runtime dependencies (if any)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m exporter

COPY --from=builder --chown=exporter:exporter --chmod=700 /app/namada-exporter /usr/local/bin/namada-exporter
COPY --chown=exporter:exporter --chmod=700 docker/namada-exporter/entrypoint.sh /opt/entrypoint.sh

USER exporter
WORKDIR /home/exporter

EXPOSE 3000

# Set the entry point
ENTRYPOINT ["/opt/entrypoint.sh"]
