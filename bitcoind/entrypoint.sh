#!/bin/bash
set -e

echo "[regtest] starting bitcoind..."
CONF_FILE="/home/bitcoin/.bitcoin/bitcoin.conf"
LOG_FILE="/home/bitcoin/.bitcoin/regtest/debug.log"

# ÄNDERUNG: -daemon hinzugefügt, damit das Skript sofort weiterläuft
bitcoind -regtest -conf="$CONF_FILE" -daemon


RPC="bitcoin-cli -regtest -rpcuser=user -rpcpassword=pass"

echo "[regtest] waiting for node..."

while true; do
  if ! pidof bitcoind > /dev/null; then
    echo "CRITICAL ERROR: bitcoind process died! Check config or network IPs."
    exit 1
  fi

  $RPC getblockchaininfo >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 1
done

echo "[regtest] node ready"

# Wallet readiness prüfen
until $RPC getwalletinfo >/dev/null 2>&1; do
  sleep 1
done

echo "[regtest] wallet subsystem ready"

sleep 5


echo "[regtest] tailing logs..."
tail -f /root/.bitcoin/regtest/debug.log