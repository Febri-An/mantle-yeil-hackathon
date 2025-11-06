import { mantle, mantleSepolia, localhost } from '@/config'

export interface ContractAddresses {
  yeil: `0x${string}`
  proofOfReserveFeed: `0x${string}`
}

// Contract addresses for each network
export const CONTRACT_ADDRESSES: Record<number, ContractAddresses> = {
  // Localhost (Anvil)
  [localhost.id]: {
    yeil: process.env.NEXT_PUBLIC_YIEL_CONTRACTS_ADDRESS as `0x${string}`, // Deployed Yeil Token
    proofOfReserveFeed: process.env.NEXT_PUBLIC_PROOF_OF_RESERVE_FEED_ADDRESS as `0x${string}`, // Deployed ProofOfReserveFeed
  },
  // Mantle Mainnet
  [mantle.id]: {
    yeil: process.env.NEXT_PUBLIC_YEIL_CONTRACTS_ADDRESS as `0x${string}`, // Replace with deployed address
    proofOfReserveFeed: process.env.NEXT_PUBLIC_PROOF_OF_RESERVE_FEED_ADDRESS as `0x${string}`, // Replace with deployed address
  },
  // Mantle Sepolia Testnet
  [mantleSepolia.id]: {
    yeil: process.env.NEXT_PUBLIC_YEIL_CONTRACTS_ADDRESS as `0x${string}`, // Replace with deployed address
    proofOfReserveFeed: process.env.NEXT_PUBLIC_PROOF_OF_RESERVE_FEED_ADDRESS as `0x${string}`, // Replace with deployed address
  },
}

// Helper function to get contract address for current chain
export function getContractAddress(
  chainId: number | undefined,
  contract: keyof ContractAddresses
): `0x${string}` | undefined {
  if (!chainId || !CONTRACT_ADDRESSES[chainId]) return undefined
  return CONTRACT_ADDRESSES[chainId][contract]
}

// Type-safe contract address getter
export function getYeilAddress(chainId: number | undefined): `0x${string}` | undefined {
  return getContractAddress(chainId, 'yeil')
}

export function getProofOfReserveFeedAddress(chainId: number | undefined): `0x${string}` | undefined {
  return getContractAddress(chainId, 'proofOfReserveFeed')
}
