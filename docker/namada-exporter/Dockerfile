FROM debian:bookworm-slim

# Install required runtime dependencies (if any)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m exporter

ADD https://github.com/MELLIFERA-Labs/namada-exporter/releases/download/v0.2.0/namada-exporter /usr/local/bin/namada-exporter
RUN echo "26da1469ce54e5256dbe8e59e98462b14f89003bd18d40e3f924938b641a7988 /usr/local/bin/namada-exporter" | sha256sum -c \
    && chown exporter:exporter /usr/local/bin/namada-exporter \
    && chmod 700 /usr/local/bin/namada-exporter

COPY --chown=exporter:exporter --chmod=700 docker/namada-exporter/entrypoint.sh /opt/entrypoint.sh

USER exporter
WORKDIR /home/exporter

EXPOSE 3000

# Set the entry point
ENTRYPOINT ["/opt/entrypoint.sh"]
