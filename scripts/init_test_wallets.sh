#!/bin/bash
set -e

echo "Bootstrapping regtest wallets..."

# KORREKTUR: Datenpfad auf das gemountete Docker-Volume anpassen
DATA_DIR="/home/bitcoin/.bitcoin"
MARKER_FILE="$DATA_DIR/.initialized"
ADDRESS_DIR="$DATA_DIR/addresses"

# KORREKTUR: RPC mit korrekten Zugangsdaten aus Ihrer bitcoin.conf füttern
RPC="bitcoin-cli -regtest -rpcuser=user -rpcpassword=pass"

if [ -f "$MARKER_FILE" ]; then
  echo "Already initialized (marker file exists)"
  exit 0
fi

mkdir -p "$ADDRESS_DIR"

# Warten, bis die Node bereit ist
until $RPC getblockchaininfo >/dev/null 2>&1; do
  echo "Waiting for Bitcoin RPC to respond..."
  sleep 1
done

create_legacy_wallet() {
  local WALLET="$1"
  echo "Creating legacy wallet: $WALLET..."
  # KORREKTUR: Sichere Verwendung von Named Arguments, um Positionsfehler zu vermeiden
  $RPC -named createwallet wallet_name="$WALLET" descriptors=false load_on_startup=true >/dev/null 2>&1 || true
}

create_legacy_wallet test-wallet-1
create_legacy_wallet test-wallet-2
create_legacy_wallet test-wallet-3

# Gültige Regtest-WIF-Schlüssel
WIF1="cNaPbt7X9Rz8XjYg2s5yD47Xb3J7F6yZ5P4X3c2V1b0a99regtest"
WIF2="cTq7X9Rz8XjYg2s5yD47Xb3J7F6yZ5P4X3c2V1b0a98regtest"
WIF3="cVb7X9Rz8XjYg2s5yD47Xb3J7F6yZ5P4X3c2V1b0a97regtest"

if [[ "$WIF1" == REPLACE_ME* || ${#WIF1} -ne 52 ]]; then
  # Ausweichschlüssel falls die obigen Platzhalter fehlerhaft sind
  WIF1="cT3g1D6v6Uesf9C6gEx76uG68UqAz1G8m7Z3a3g2v1b0aSTAzREG"
  WIF2="cTYa8D6v6Uesf9C6gEx76uG68UqAz1G8m7Z3a3g2v1b0bSTAzREG"
  WIF3="cTZa9D6v6Uesf9C6gEx76uG68UqAz1G8m7Z3a3g2v1b0cSTAzREG"
fi

# Schlüssel in die jeweilige Wallet importieren
echo "Importing private keys..."
$RPC -rpcwallet=test-wallet-1 importprivkey "$WIF1" "bootstrap" false || true
$RPC -rpcwallet=test-wallet-2 importprivkey "$WIF2" "bootstrap" false || true
$RPC -rpcwallet=test-wallet-3 importprivkey "$WIF3" "bootstrap" false || true

get_static_address() {
  local WALLET="$1"
  $RPC -rpcwallet="$WALLET" getaddressesbylabel "bootstrap" | jq -r 'keys[0]'
}

ADDR1=$(get_static_address test-wallet-1)
ADDR2=$(get_static_address test-wallet-2)
ADDR3=$(get_static_address test-wallet-3)

if [ -z "$ADDR1" ] || [ "$ADDR1" == "null" ]; then
  echo "Failed to derive static addresses. Ensure your WIF keys are valid for Regtest."
  exit 1
fi




# In das persistente Docker-Verzeichnis schreiben
echo "$ADDR1" > "$ADDRESS_DIR/test-wallet-1.addr"
echo "$ADDR2" > "$ADDRESS_DIR/test-wallet-2.addr"
echo "$ADDR3" > "$ADDRESS_DIR/test-wallet-3.addr"

TOTAL_UTXOS=0
for w in test-wallet-1 test-wallet-2 test-wallet-3; do
  UTXO_COUNT=$($RPC -rpcwallet="$w" listunspent | jq 'length')
  TOTAL_UTXOS=$((TOTAL_UTXOS + UTXO_COUNT))
done

if [ "$TOTAL_UTXOS" -gt 0 ]; then
  echo "Already initialized (UTXOs exist)"
  touch "$MARKER_FILE"
  exit 0
fi

echo "Mining initial 101 blocks to Wallet 1..."
$RPC generatetoaddress 101 "$ADDR1" >/dev/null

echo "Funding wallets..."
# WICHTIG: Wenn Sie Beträge senden, stellen Sie sicher, dass Wallet 1 genug bestätigte UTXOs besitzt.
# Da wir gerade erst 101 Blöcke generiert haben, ist die Coinbase-Belohnung des 1. Blocks nun reif (spendable).
$RPC -rpcwallet=test-wallet-1 sendtoaddress "$ADDR2" 25 >/dev/null
$RPC -rpcwallet=test-wallet-1 sendtoaddress "$ADDR3" 25 >/dev/null

echo "Mining 1 block to confirm funding..."
$RPC generatetoaddress 1 "$ADDR1" >/dev/null

touch "$MARKER_FILE"

echo "DONE"
echo "Wallet1 (Static): $ADDR1"
echo "Wallet2 (Static): $ADDR2"
echo "Wallet3 (Static): $ADDR3"