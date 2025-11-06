# Contract ABIs

This directory contains the contract ABIs that are automatically generated from the compiled Solidity contracts.

## Files

- **`yeil-abi.ts`** - Exports the Yeil token contract ABI
- **`proof-of-reserve-abi.ts`** - Exports the ProofOfReserveFeed contract ABI
- **`addresses.ts`** - Contract addresses for different networks
- **`index.ts`** - Centralized exports for all contract-related modules
- **`*-generated.json`** - Auto-generated JSON files from compiled contracts (do not edit manually)

## How It Works

The ABIs are automatically exported from the Foundry-compiled contracts located in `contracts/out/`. The TypeScript files import these generated JSON files to provide type-safe contract interfaces.

### Workflow

1. **Build contracts**: `cd contracts && forge build`
2. **Export ABIs**: The ABIs are extracted from `contracts/out/[Contract].sol/[Contract].json`
3. **Import in TypeScript**: The TypeScript files import the generated JSON files

## Updating ABIs

After making changes to the Solidity contracts, you need to regenerate the ABIs:

### Option 1: Using npm script (Recommended)

```bash
cd web
npm run export-abis
```

### Option 2: Using PowerShell script

```powershell
pwsh scripts/export-abis.ps1
```

### Option 3: Using Bash script

```bash
bash scripts/export-abis.sh
```

### Option 4: Manual export

```powershell
# In the contracts directory
cd contracts
forge build

# Export Yeil ABI
(Get-Content "out\Yeil.sol\Yeil.json" | ConvertFrom-Json).abi | ConvertTo-Json -Depth 10 | Out-File -FilePath "..\web\lib\contracts\yeil-abi-generated.json" -Encoding utf8

# Export ProofOfReserveFeed ABI
(Get-Content "out\ProofOfReserveFeed.sol\ProofOfReserveFeed.json" | ConvertFrom-Json).abi | ConvertTo-Json -Depth 10 | Out-File -FilePath "..\web\lib\contracts\proof-of-reserve-abi-generated.json" -Encoding utf8
```

## Usage

Import the ABIs in your React components or hooks:

```typescript
import { YEIL_ABI, PROOF_OF_RESERVE_ABI, getYeilAddress } from '@/lib/contracts'

// Use with wagmi hooks
const { data } = useReadContract({
  address: getYeilAddress(chainId),
  abi: YEIL_ABI,
  functionName: 'balanceOf',
  args: [address],
})
```

## Why This Approach?

1. **Single Source of Truth**: ABIs are generated directly from compiled contracts, ensuring consistency
2. **Type Safety**: TypeScript can infer types from the imported ABIs
3. **Automatic Updates**: Running the export script after contract changes keeps ABIs in sync
4. **No Manual Maintenance**: No need to manually copy-paste ABIs or update function signatures

## Contract Addresses

Update the contract addresses in `addresses.ts` after deploying contracts to different networks:

```typescript
export const CONTRACT_ADDRESSES: Record<number, ContractAddresses> = {
  // Mantle Mainnet
  [mantle.id]: {
    yeil: '0xYourDeployedAddress',
    proofOfReserveFeed: '0xYourDeployedAddress',
  },
  // Mantle Sepolia Testnet
  [mantleSepolia.id]: {
    yeil: '0xYourDeployedAddress',
    proofOfReserveFeed: '0xYourDeployedAddress',
  },
}
```
