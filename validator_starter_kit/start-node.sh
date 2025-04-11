#!/bin/bash

echo "🔐 Please enter a password to secure your wallet:"
read -s WALLET_PASSWORD

mkdir -p node-data

echo "🧠 Creating new account..."
./geth account new --datadir node-data --password <(echo "$WALLET_PASSWORD")

ACCOUNT_ADDRESS=$(./geth account list --datadir node-data | head -n 1 | cut -d '{' -f2 | cut -d '}' -f1)

echo "🟢 Initializing node..."
./geth init --datadir node-data genesis.json

echo "🚀 Starting your node..."
./geth --datadir node-data \
  --networkid 22550 \
  --port 30303 \
  --http --http.addr 0.0.0.0 --http.port 8545 \
  --http.api eth,net,web3,personal,miner \
  --http.corsdomain "*" --http.vhosts "*" \
  --mine \
  --allow-insecure-unlock \
  --unlock $ACCOUNT_ADDRESS \
  --password <(echo "$WALLET_PASSWORD") \
  --nodiscover --verbosity 3
