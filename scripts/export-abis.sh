#!/bin/bash
# Export ABIs from compiled contracts to web/lib/contracts

set -e

echo "🔧 Exporting Contract ABIs..."

# Change to contracts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../contracts"

# Build contracts first
echo "📦 Building contracts..."
forge build

WEB_CONTRACTS_DIR="$SCRIPT_DIR/../web/lib/contracts"

# Export Yeil ABI
echo "📄 Exporting Yeil ABI..."
YEIL_JSON_PATH="out/Yeil.sol/Yeil.json"
YEIL_OUTPUT_PATH="$WEB_CONTRACTS_DIR/yeil-abi-generated.json"

if [ -f "$YEIL_JSON_PATH" ]; then
    jq '.abi' "$YEIL_JSON_PATH" > "$YEIL_OUTPUT_PATH"
    echo "✅ Yeil ABI exported to: $YEIL_OUTPUT_PATH"
else
    echo "❌ Yeil.json not found at: $YEIL_JSON_PATH"
    exit 1
fi

# Export ProofOfReserveFeed ABI
echo "📄 Exporting ProofOfReserveFeed ABI..."
PROOF_JSON_PATH="out/ProofOfReserveFeed.sol/ProofOfReserveFeed.json"
PROOF_OUTPUT_PATH="$WEB_CONTRACTS_DIR/proof-of-reserve-abi-generated.json"

if [ -f "$PROOF_JSON_PATH" ]; then
    jq '.abi' "$PROOF_JSON_PATH" > "$PROOF_OUTPUT_PATH"
    echo "✅ ProofOfReserveFeed ABI exported to: $PROOF_OUTPUT_PATH"
else
    echo "❌ ProofOfReserveFeed.json not found at: $PROOF_JSON_PATH"
    exit 1
fi

echo ""
echo "🎉 All ABIs exported successfully!"
echo ""
echo "📝 Note: The TypeScript files (yeil-abi.ts, proof-of-reserve-abi.ts) import these generated JSON files."
