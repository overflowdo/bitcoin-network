#!/bin/bash
set -e

echo "🚀 Bootstrapping regtest wallets..."

RPC="bitcoin-cli -regtest"


if [ -f /data/.initialized ]; then
  echo "⏭️ Already initialized (marker file exists)"
  exit 0
fi

mkdir -p /data/addresses


until $RPC getblockchaininfo >/dev/null 2>&1; do
  sleep 1
done



create_wallet() {
  local WALLET="$1"

  $RPC createwallet "$WALLET" >/dev/null 2>&1 || true
}

create_wallet test-wallet-1
create_wallet test-wallet-2
create_wallet test-wallet-3


WIF1="REPLACE_ME_WIF_1"
WIF2="REPLACE_ME_WIF_2"
WIF3="REPLACE_ME_WIF_3"



$RPC -rpcwallet=test-wallet-1 importprivkey "$WIF1" "bootstrap" false || true
$RPC -rpcwallet=test-wallet-2 importprivkey "$WIF2" "bootstrap" false || true
$RPC -rpcwallet=test-wallet-3 importprivkey "$WIF3" "bootstrap" false || true



get_first_address() {
  local WALLET="$1"

  # stabiler als getaddressesbylabel
  $RPC -rpcwallet="$WALLET" listreceivedbyaddress 0 true \
    | jq -r '.[0].address // empty'
}

ADDR1=$(get_first_address test-wallet-1)
ADDR2=$(get_first_address test-wallet-2)
ADDR3=$(get_first_address test-wallet-3)

if [ -z "$ADDR1" ] || [ -z "$ADDR2" ] || [ -z "$ADDR3" ]; then
  echo "Failed to derive addresses"
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
  echo "⏭Already initialized (UTXOs exist)"
  touch /data/.initialized
  exit 0
fi


echo "Mining initial blocks..."

$RPC generatetoaddress 101 "$ADDR1"

echo "Funding wallets..."

$RPC -rpcwallet=test-wallet-1 sendtoaddress "$ADDR2" 25
$RPC -rpcwallet=test-wallet-1 sendtoaddress "$ADDR3" 25

$RPC generatetoaddress 1 "$ADDR1"
$RPC generatetoaddress 50 "$ADDR1"


touch /data/.initialized

echo "DONE"

echo "Wallet1: $ADDR1"
echo "Wallet2: $ADDR2"
echo "Wallet3: $ADDR3"