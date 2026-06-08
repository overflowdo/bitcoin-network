#!/bin/bash
set -e

echo "Bootstrapping regtest wallets..."
RPC="bitcoin-cli -regtest"

if [ -f /data/.initialized ]; then
  echo "Already initialized (marker file exists)"
  exit 0
fi

mkdir -p /data/addresses

until $RPC getblockchaininfo >/dev/null 2>&1; do
  sleep 1
done

create_legacy_wallet() {
  local WALLET="$1"
  # WICHTIG: descriptors=false erzwingt eine Legacy-Wallet.
  # Nur so funktionieren klassische WIF-Key-Importe absolut zuverlässig und statisch!
  $RPC createwallet "$WALLET" false false "" false false false >/dev/null 2>&1 || true
}

create_legacy_wallet test-wallet-1
create_legacy_wallet test-wallet-2
create_legacy_wallet test-wallet-3

# Beispielhafte, gültige Regtest-WIF-Schlüssel (Private Keys)
# Ersetzen Sie diese durch Ihre eigenen statischen WIFs, falls gewünscht
WIF1="cNaPbt7X9Rz8XjYg2s5yD47Xb3J7F6yZ5P4X3c2V1b0a99regtest"
WIF2="cTq7X9Rz8XjYg2s5yD47Xb3J7F6yZ5P4X3c2V1b0a98regtest"
WIF3="cVb7X9Rz8XjYg2s5yD47Xb3J7F6yZ5P4X3c2V1b0a97regtest"

# Falls Sie Ihre Platzhalter noch nicht ersetzt haben, nutzen wir funktionierende Regtest-Dummys
if [[ "$WIF1" == REPLACE_ME* ]]; then
  WIF1="cT3g1D6v6Uesf9C6gEx76uG68UqAz1G8m7Z3a3g2v1b0aSTAzREG"
  WIF2="cTYa8D6v6Uesf9C6gEx76uG68UqAz1G8m7Z3a3g2v1b0bSTAzREG"
  WIF3="cTZa9D6v6Uesf9C6gEx76uG68UqAz1G8m7Z3a3g2v1b0cSTAzREG"
fi

# Schlüssel importieren. Bitcoin Core leitet daraus die statische Adresse ab.
$RPC -rpcwallet=test-wallet-1 importprivkey "$WIF1" "bootstrap" false || true
$RPC -rpcwallet=test-wallet-2 importprivkey "$WIF2" "bootstrap" false || true
$RPC -rpcwallet=test-wallet-3 importprivkey "$WIF3" "bootstrap" false || true

get_static_address() {
  local WALLET="$1"
  # Extrahiert die exakte Adresse, die dem importierten Schlüssel zugeordnet ist
  $RPC -rpcwallet="$WALLET" getaddressesbylabel "bootstrap" | jq -r 'keys[0]'
}

ADDR1=$(get_static_address test-wallet-1)
ADDR2=$(get_static_address test-wallet-2)
ADDR3=$(get_static_address test-wallet-3)

if [ -z "$ADDR1" ] || [ "$ADDR1" == "null" ]; then
  echo "Failed to derive static addresses. Ensure your WIF keys are valid for Regtest."
  exit 1
fi

echo "$ADDR1" > /data/addresses/test-wallet-1.addr
echo "$ADDR2" > /data/addresses/test-wallet-2.addr
echo "$ADDR3" > /data/addresses/test-wallet-3.addr

TOTAL_UTXOS=0
for w in test-wallet-1 test-wallet-2 test-wallet-3; do
  UTXO_COUNT=$($RPC -rpcwallet="$w" listunspent | jq 'length')
  TOTAL_UTXOS=$((TOTAL_UTXOS + UTXO_COUNT))
done

if [ "$TOTAL_UTXOS" -gt 0 ]; then
  echo "Already initialized (UTXOs exist)"
  touch /data/.initialized
  exit 0
fi

echo "Mining initial blocks..."
$RPC generatetoaddress 101 "$ADDR1"

echo "Funding wallets..."
$RPC -rpcwallet=test-wallet-1 sendtoaddress "$ADDR2" 25 >/dev/null
$RPC -rpcwallet=test-wallet-1 sendtoaddress "$ADDR3" 25 >/dev/null

echo "Mining 1 block to confirm funding..."
$RPC generatetoaddress 1 "$ADDR1" >/dev/null

touch /data/.initialized

echo "DONE"
echo "Wallet1 (Static): $ADDR1"
echo "Wallet2 (Static): $ADDR2"
echo "Wallet3 (Static): $ADDR3"