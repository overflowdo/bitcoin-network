#!/bin/bash
set -e

echo "[regtest] starting bitcoind..."
# KORREKTUR: Pfade laut Ihrem Dockerfile angepasst (/root/.bitcoin/)
CONF_FILE="/root/.bitcoin/bitcoin.conf"
LOG_FILE="/root/.bitcoin/regtest/debug.log"

# bitcoind mit absolutem Pfad starten
/root/bitcoind -regtest -conf="$CONF_FILE" -daemon

# KORREKTUR: Absoluter Pfad zu /root/bitcoin-cli zwingend erforderlich!
RPC="/root/bitcoin-cli -regtest -rpcuser=user -rpcpassword=pass"

echo "[regtest] waiting for node..."

# Temporär set -e deaktivieren, damit der Schleifen-Check nicht hart abbricht
set +e
while true; do
  # KORREKTUR: native Prüfung via "ps", da "pidof" im Image fehlt
  if ! ps aux | grep '[b]itcoind' > /dev/null; then
    echo "CRITICAL ERROR: bitcoind process died! Check config or network IPs."
    exit 1
  fi

  # RPC-Abfrage testen
  $RPC getblockchaininfo >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 1
done
set -e # set -e wieder aktivieren

echo "[regtest] node ready"

# Wallet readiness prüfen
set +e
until $RPC getwalletinfo >/dev/null 2>&1; do
  sleep 1
done
set -e

echo "[regtest] wallet subsystem ready"
sleep 5

echo "[regtest] tailing logs..."
# KORREKTUR: Pfad auf die Variable angepasst
tail -f "$LOG_FILE"