#!/bin/bash

# === CONFIG ===
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
NODE_DIR="node-data-$TIMESTAMP"
KEY_FILE="wallet.json"
PASSWORD_FILE="password.txt"

# 1. Ask for wallet password
echo "🔐 Please enter a password to protect your validator wallet:"
read -s WALLET_PASSWORD

# 2. Generate wallet only if it doesn't exist
if [ ! -f "$KEY_FILE" ]; then
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
else
  echo "📄 Wallet already exists. Reusing existing $KEY_FILE"
fi

# 3. Extract wallet info
ADDRESS=$(jq -r .address $KEY_FILE)
PRIVATE_KEY=$(jq -r .privateKey $KEY_FILE)
MNEMONIC=$(jq -r .mnemonic $KEY_FILE)

# 4. Show user info
echo ""
echo "📍 Your validator wallet:"
echo "   Address:     $ADDRESS"
echo "   Private Key: $PRIVATE_KEY"
echo "   Mnemonic:    $MNEMONIC"
echo "⚠️  Save these securely! Never share them with anyone!"
echo ""

# 5. Create keystore directory and import key
mkdir -p "$NODE_DIR/keystore"
echo "$PRIVATE_KEY" > tempkey.txt
echo "$WALLET_PASSWORD" > $PASSWORD_FILE

# Fix potential format issues: strip 0x if needed
CLEAN_KEY=$(echo "$PRIVATE_KEY" | sed 's/^0x//')
echo "$CLEAN_KEY" > tempkey.txt

./geth account import --datadir "$NODE_DIR" --password "$PASSWORD_FILE" tempkey.txt
rm tempkey.txt

# 6. Initialize the genesis block
echo "🌱 Initializing genesis..."
./geth init --datadir "$NODE_DIR" genesis.json

# 7. Start the node
echo "🚀 Starting your validator node..."
./geth --datadir "$NODE_DIR" \
  --networkid 22550 \
  --port 30303 \
  --http --http.addr "0.0.0.0" --http.port 8545 \
  --http.api eth,net,web3,personal,miner \
  --http.corsdomain "*" --http.vhosts "*" \
  --mine \
  --miner.etherbase "$ADDRESS" \
  --allow-insecure-unlock \
  --unlock "$ADDRESS" \
  --password "$PASSWORD_FILE" \
  --nat extip:$(curl -s ifconfig.me) \
  --nodiscover --verbosity 3
