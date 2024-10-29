
# Namada-UP !
This repository is a set of docker images and tools to let you run Namada Node with out of the box Monitoring dashboard in a matter of seconds!

Thanks to  MELLIFERA-Labs for  [Namada-exporter](https://github.com/MELLIFERA-Labs/namada-exporter) and [CometBFT](https://github.com/cometbft/cometbft) for dashboards

This file will be turned into a detailed guide very soon. Stay tuned.

### init
set .env variables

run ephemeral container
NAMADA_NETWORK_CONFIGS_SERVER
NODE_P2P_PORT
NODE_RPC_PORT
NAMADA_LEDGER__CHAIN_ID
NAMADA_LEDGER__COMETBFT__P2P__EXTERNAL_ADDRESS
NAMADA_LEDGER__COMETBFT__P2P__PERSISTENT_PEERS
or
NAMADA_LEDGER__COMETBFT__P2P__SEEDS


```bash
docker compose --profile node run --rm --entrypoint /bin/bash  node
```
when insdie
```bash
namadac utils join-network --chain-id $NAMADA_LEDGER__CHAIN_ID
```
then exit

now run the node 

```bash
docker compose --profile node up -d
```