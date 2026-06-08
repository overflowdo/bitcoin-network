#!/bin/bash
set -e

echo "[regtest] starting bitcoind..."

# ÄNDERUNG: -daemon hinzugefügt, damit das Skript sofort weiterläuft
/root/bitcoind -regtest -daemon -server -fallbackfee=0.0002 -rpcallowip=0.0.0.0/0 -rpcbind=0.0.0.0 -blockfilterindex=1 -peerblockfilters=1

RPC="bitcoin-cli -regtest"

echo "[regtest] waiting for node..."

until $RPC getblockchaininfo >/dev/null 2>&1; do
  sleep 1
done

echo "[regtest] node ready"

# Wallet readiness prüfen
until $RPC getwalletinfo >/dev/null 2>&1; do
  sleep 1
done

echo "[regtest] wallet subsystem ready"

sleep 5

bash /scripts/init_test_wallet.sh

# ÄNDERUNG: Da bitcoind im Hintergrund läuft, würde der Container jetzt stoppen.
# Wir hängen uns an die Logdatei an, um den Container aktiv zu halten und Logs zu sehen.
tail -f /root/.bitcoin/regtest/debug.log