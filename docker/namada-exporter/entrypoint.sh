#!/bin/bash
# This entrypoint updates config files from ENV variable each time container is started,
# so we always using the latest version of env variables in config file without needing to manually modify config file
# Update configs with env variables

rm -f /home/exporter/config.toml
echo port = 3000 > /home/exporter/config.toml
echo validator_tm_address = \""$NAMADA_EXPORTER_VAL_ADDR"\" >> /home/exporter/config.toml
echo validator_http_rpc = \""$NAMADA_EXPORTER_HTTP_RPC"\" >> /home/exporter/config.toml

cat /home/exporter/config.toml
/usr/local/bin/namada-exporter start --config /home/exporter/config.toml