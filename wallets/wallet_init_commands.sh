#!/bin/bash
 
RPC="docker exec bitcoind-regtest /root/bitcoin-cli -regtest"
 
OUT_DIR="wallet_registry"
mkdir "wallets"
 
sudo docker exec bitcoind-regtest /root/bitcoin-cli createwallet wallet1 false false "" false true
sudo docker exec bitcoind-regtest /root/bitcoin-cli createwallet wallet2 false false "" false true
sudo docker exec bitcoind-regtest /root/bitcoin-cli createwallet wallet3 false false "" false true
 
for W in wallet1 wallet2 wallet3; do
  echo "Exporting $W..."
 
  $RPC -rpcwallet="$W" listdescriptors true > "wallets/$W.descriptors.json"
 
done
 
echo "DONE"