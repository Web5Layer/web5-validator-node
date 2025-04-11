#!/bin/bash

# Step 1: Generate wallet using ethers.js
echo "🧠 Generating wallet..."
node <<EOF > wallet.json
const { ethers } = require("ethers");
const wallet = ethers.Wallet.createRandom();
console.log(JSON.stringify({
  address: wallet.address,
  privateKey: wallet.privateKey,
  mnemonic: wallet.mnemonic.phrase
}, null, 2));
EOF

# Step 2: Parse wallet info
ADDRESS=$(jq -r .address wallet.json)
PRIVATE_KEY=$(jq -r .privateKey wallet.json)
MNEMONIC=$(jq -r .mnemonic wallet.json)

echo ""
echo "📍 Your new validator wallet:"
echo "   Address:     $ADDRESS"
echo "   Private Key: $PRIVATE_KEY"
echo "   Mnemonic:    $MNEMONIC"
echo "⚠️  Make sure to save these securely!"
echo ""

# Step 3: Ask for password
echo "🔐 Please enter a password to protect your keystore:"
read -s WALLET_PASSWORD

# Step 4: Create keystore directory
mkdir -p node-data/keystore

# Step 5: Import private key into Geth
echo $PRIVATE_KEY > tempkey.txt
echo $WALLET_PASSWORD > password.txt
./geth account import --datadir node-data --password password.txt tempkey.txt

# Step 6: Clean up temp files
rm tempkey.txt

# Step 7: Run the node
echo "🚀 Starting node with your validator..."
./geth --datadir node-data \
  --networkid 22550 \
  --port 30303 \
  --http --http.addr 0.0.0.0 --http.port 8545 \
  --http.api eth,net,web3,personal,miner \
  --http.corsdomain "*" --http.vhosts "*" \
  --mine \
  --allow-insecure-unlock \
  --unlock "$ADDRESS" \
  --password password.txt \
  --nodiscover --verbosity 3

