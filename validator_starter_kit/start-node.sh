#!/bin/bash

# === CONFIG ===
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
NODE_DIR="node-data-$TIMESTAMP"
KEY_FILE="wallet.json"
PASSWORD_FILE="password.txt"

echo "🔐 Please enter a password to protect your validator wallet:"
read -s WALLET_PASSWORD

echo "🔧 Creating your wallet using ethers.js..."
node <<EOF > $KEY_FILE
const { ethers } = require("ethers");
const wallet = ethers.Wallet.createRandom();
console.log(JSON.stringify({
  address: wallet.address,
  privateKey: wallet.privateKey,
  mnemonic: wallet.mnemonic.phrase
}, null, 2));
EOF

# Extract wallet info
ADDRESS=$(jq -r .address $KEY_FILE)
PRIVATE_KEY=$(jq -r .privateKey $KEY_FILE)
MNEMONIC=$(jq -r .mnemonic $KEY_FILE)

# Show wallet details
echo ""
echo "📍 Your new validator wallet:"
echo "   Address:     $ADDRESS"
echo "   Private Key: $PRIVATE_KEY"
echo "   Mnemonic:    $MNEMONIC"
echo "⚠️  Save these somewhere safe!"
echo ""

# Create new data directory
mkdir -p $NODE_DIR/keystore

# Save password and import private key
echo "$PRIVATE_KEY" > tempkey.txt
echo "$WALLET_PASSWORD" > $PASSWORD_FILE
./geth account import --datadir $NODE_DIR --password $PASSWORD_FILE tempkey.txt

# Remove raw key for safety
rm tempkey.txt

# Initialize the genesis
echo "🌱 Initializing genesis..."
./geth init --datadir $NODE_DIR genesis.json

# Start the node
echo "🚀 Starting your validator node..."
./geth --datadir $NODE_DIR \
  --networkid 22550 \
  --port 30303 \
  --http --http.addr 0.0.0.0 --http.port 8545 \
  --http.api eth,net,web3,personal,miner \
  --http.corsdomain "*" --http.vhosts "*" \
  --mine \
  --allow-insecure-unlock \
  --unlock "$ADDRESS" \
  --etherbase "$ADDRESS" \
  --password $PASSWORD_FILE \
  --nodiscover --verbosity 3
