#!/bin/bash

lavad config chain-id $CHAIN_ID
lavad config keyring-backend file
lavad init $MONIKER --chain-id $CHAIN_ID

wget https://storage.googleapis.com/lavanet-public-asssets/tge/genesis.json -O $HOME/.lava/config/genesis.json
#Then verify the correctness of the genesis configuration file:
lavad validate-genesis

### config.toml changes
sed -i \
-e 's|^timeout_propose =.*|timeout_propose = "10s"|' \
-e 's|^timeout_propose_delta =.*|timeout_propose_delta = "500ms"|' \
-e 's|^timeout_prevote =.*|timeout_prevote = "1s"|' \
-e 's|^timeout_prevote_delta =.*|timeout_prevote_delta = "500ms"|' \
-e 's|^timeout_precommit =.*|timeout_precommit = "500ms"|' \
-e 's|^timeout_precommit_delta =.*|timeout_precommit_delta = "1s"|' \
-e 's|^timeout_commit =.*|timeout_commit = "15s"|' \
-e 's|^create_empty_blocks =.*|create_empty_blocks = true|' \
-e 's|^create_empty_blocks_interval =.*|create_empty_blocks_interval = "15s"|' \
-e 's|^timeout_broadcast_tx_commit =.*|timeout_broadcast_tx_commit = "151s"|' \
-e 's|^skip_timeout_commit =.*|skip_timeout_commit = false|' \
-e 's|^indexer =.*|indexer = "null"|' \
$HOME/.lava/config/config.toml