#!/bin/bash
set -e

echo "[regtest] starting bitcoind..."

bitcoind \
  -conf=/home/bitcoin/.bitcoin/bitcoin.conf \
  -datadir=/home/bitcoin/.bitcoin &

RPC="bitcoin-cli -regtest"

echo "[regtest] waiting for node..."

until $RPC getblockchaininfo >/dev/null 2>&1; do
  sleep 1
done

echo "[regtest] node ready"

# Wallet readiness  prüfen
until $RPC getwalletinfo >/dev/null 2>&1; do
  sleep 1
done

echo "[regtest] wallet subsystem ready"

bash /scripts/init_test_wallet.sh

wait