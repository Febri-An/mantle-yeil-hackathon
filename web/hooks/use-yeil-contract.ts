'use client'

import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { useCallback, useEffect } from 'react'
import { parseEther, formatEther } from 'viem'
import { YEIL_ABI, getYeilAddress } from '@/lib/contracts'

export interface YeilTokenInfo {
  name: string
  symbol: string
  decimals: number
  totalSupply: bigint
  verifiedReserves: bigint
  isFullyBacked: boolean
  proofOfReserveFeedAddress: `0x${string}`
}

export interface YeilBalance {
  balance: bigint
  balanceFormatted: string
}

export interface YeilSnapshotData {
  snapshotId: number
  balanceAtSnapshot: bigint
  totalSupplyAtSnapshot: bigint
}

// Hook for reading Yeil token information
export function useYeilTokenInfo() {
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const { data: name, isLoading: isLoadingName } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'getTokenName',
  }) as { data: string | undefined; isLoading: boolean }

  const { data: symbol, isLoading: isLoadingSymbol } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'getTokenSymbol',
  }) as { data: string | undefined; isLoading: boolean }

  const { data: decimals, isLoading: isLoadingDecimals } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'decimals',
  }) as { data: number | undefined; isLoading: boolean }

  const { data: totalSupply, isLoading: isLoadingTotalSupply, refetch: refetchTotalSupply } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'totalSupply',
  }) as { data: bigint | undefined; isLoading: boolean; refetch: () => void }

  const { data: verifiedReserves, isLoading: isLoadingReserves, refetch: refetchReserves } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'getVerifiedReserves',
  }) as { data: bigint | undefined; isLoading: boolean; refetch: () => void }

  const { data: isFullyBacked, isLoading: isLoadingBacked, refetch: refetchBacked } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'isFullyBacked',
  }) as { data: boolean | undefined; isLoading: boolean; refetch: () => void }

  const { data: proofOfReserveFeedAddress } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'getProofOfReserveAddress',
  }) as { data: `0x${string}` | undefined }

  const isLoading = isLoadingName || isLoadingSymbol || isLoadingDecimals || 
                   isLoadingTotalSupply || isLoadingReserves || isLoadingBacked

  const refetch = useCallback(() => {
    refetchTotalSupply()
    refetchReserves()
    refetchBacked()
  }, [refetchTotalSupply, refetchReserves, refetchBacked])

  const tokenInfo: YeilTokenInfo | undefined = name && symbol && decimals !== undefined ? {
    name,
    symbol,
    decimals,
    totalSupply: totalSupply || 0n,
    verifiedReserves: verifiedReserves || 0n,
    isFullyBacked: isFullyBacked || false,
    proofOfReserveFeedAddress: proofOfReserveFeedAddress || '0x0000000000000000000000000000000000000000',
  } : undefined

  return {
    tokenInfo,
    isLoading,
    refetch,
  }
}

// Hook for reading user balance
export function useYeilBalance(address?: `0x${string}`) {
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const { data: balance, isLoading, refetch } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'getBalance',
    args: address ? [address] : undefined,
  }) as { data: bigint | undefined; isLoading: boolean; refetch: () => void }

  const balanceData: YeilBalance | undefined = balance !== undefined ? {
    balance,
    balanceFormatted: formatEther(balance),
  } : undefined

  return {
    balance: balanceData,
    isLoading,
    refetch,
  }
}

// Hook for reading balance at a specific snapshot
export function useYeilBalanceAt(address?: `0x${string}`, snapshotId?: number) {
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const { data: balance, isLoading } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'balanceOfAt',
    args: address && snapshotId !== undefined ? [address, BigInt(snapshotId)] : undefined,
  }) as { data: bigint | undefined; isLoading: boolean }

  return {
    balance: balance || 0n,
    balanceFormatted: balance ? formatEther(balance) : '0',
    isLoading,
  }
}

// Hook for reading total supply at a specific snapshot
export function useYeilTotalSupplyAt(snapshotId?: number) {
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const { data: totalSupply, isLoading } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'totalSupplyAt',
    args: snapshotId !== undefined ? [BigInt(snapshotId)] : undefined,
  }) as { data: bigint | undefined; isLoading: boolean }

  return {
    totalSupply: totalSupply || 0n,
    totalSupplyFormatted: totalSupply ? formatEther(totalSupply) : '0',
    isLoading,
  }
}

// Hook for minting tokens (owner only)
export function useYeilMint() {
  const { writeContractAsync, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const mint = useCallback(
    async (to: `0x${string}`, amount: string) => {
      if (!contractAddress) throw new Error('Contract address not found for this network')
      
      try {
        // Use writeContractAsync which simulates first and returns a promise
        const txHash = await writeContractAsync({
          address: contractAddress,
          abi: YEIL_ABI,
          functionName: 'mint',
          args: [to, parseEther(amount)],
        })
        
        return txHash
      } catch (err) {
        console.error('Mint error:', err)
        throw err
      }
    },
    [contractAddress, writeContractAsync]
  )

  return {
    mint,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  }
}

// Hook for burning tokens (owner only)
export function useYeilBurn() {
  const { writeContractAsync, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const burn = useCallback(
    async (from: `0x${string}`, amount: string) => {
      if (!contractAddress) throw new Error('Contract address not found for this network')
      
      try {
        const txHash = await writeContractAsync({
          address: contractAddress,
          abi: YEIL_ABI,
          functionName: 'burn',
          args: [from, parseEther(amount)],
        })
        
        return txHash
      } catch (err) {
        console.error('Burn error:', err)
        throw err
      }
    },
    [contractAddress, writeContractAsync]
  )

  return {
    burn,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  }
}

// Hook for creating snapshot (owner only)
export function useYeilSnapshot() {
  const { writeContractAsync, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const createSnapshot = useCallback(async () => {
    if (!contractAddress) throw new Error('Contract address not found for this network')
    
    try {
      const txHash = await writeContractAsync({
        address: contractAddress,
        abi: YEIL_ABI,
        functionName: 'snapshot',
      })
      
      return txHash
    } catch (err) {
      console.error('Snapshot error:', err)
      throw err
    }
  }, [contractAddress, writeContractAsync])

  return {
    createSnapshot,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  }
}

// Hook for ERC20 transfer
export function useYeilTransfer() {
  const { writeContractAsync, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const transfer = useCallback(
    async (to: `0x${string}`, amount: string) => {
      if (!contractAddress) throw new Error('Contract address not found for this network')
      
      try {
        const txHash = await writeContractAsync({
          address: contractAddress,
          abi: YEIL_ABI,
          functionName: 'transfer',
          args: [to, parseEther(amount)],
        })
        
        return txHash
      } catch (err) {
        console.error('Transfer error:', err)
        throw err
      }
    },
    [contractAddress, writeContractAsync]
  )

  return {
    transfer,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  }
}

// Hook for ERC20 approve
export function useYeilApprove() {
  const { writeContractAsync, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const approve = useCallback(
    async (spender: `0x${string}`, amount: string) => {
      if (!contractAddress) throw new Error('Contract address not found for this network')
      
      try {
        const txHash = await writeContractAsync({
          address: contractAddress,
          abi: YEIL_ABI,
          functionName: 'approve',
          args: [spender, parseEther(amount)],
        })
        
        return txHash
      } catch (err) {
        console.error('Approve error:', err)
        throw err
      }
    },
    [contractAddress, writeContractAsync]
  )

  return {
    approve,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  }
}

// Hook for reading allowance
export function useYeilAllowance(owner?: `0x${string}`, spender?: `0x${string}`) {
  const { chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  const { data: allowance, isLoading, refetch } = useReadContract({
    address: contractAddress,
    abi: YEIL_ABI,
    functionName: 'allowance',
    args: owner && spender ? [owner, spender] : undefined,
  }) as { data: bigint | undefined; isLoading: boolean; refetch: () => void }

  return {
    allowance: allowance || 0n,
    allowanceFormatted: allowance ? formatEther(allowance) : '0',
    isLoading,
    refetch,
  }
}

// Comprehensive hook combining all Yeil contract functionality
export function useYeilContract() {
  const { address, chainId } = useAccount()
  const contractAddress = getYeilAddress(chainId)
  
  const { tokenInfo, isLoading: isLoadingInfo, refetch: refetchInfo } = useYeilTokenInfo()
  const { balance, isLoading: isLoadingBalance, refetch: refetchBalance } = useYeilBalance(address)
  
  const mintHook = useYeilMint()
  const burnHook = useYeilBurn()
  const snapshotHook = useYeilSnapshot()
  const transferHook = useYeilTransfer()
  const approveHook = useYeilApprove()

  // Auto-refresh data when transactions complete
  useEffect(() => {
    if (mintHook.isSuccess || burnHook.isSuccess || transferHook.isSuccess) {
      refetchInfo()
      refetchBalance()
    }
  }, [mintHook.isSuccess, burnHook.isSuccess, transferHook.isSuccess, refetchInfo, refetchBalance])

  const isLoading = isLoadingInfo || isLoadingBalance

  return {
    // Contract info
    contractAddress,
    tokenInfo,
    balance,
    isLoading,
    
    // Actions
    mint: mintHook.mint,
    burn: burnHook.burn,
    createSnapshot: snapshotHook.createSnapshot,
    transfer: transferHook.transfer,
    approve: approveHook.approve,
    
    // Transaction states
    mintState: {
      hash: mintHook.hash,
      isPending: mintHook.isPending,
      isConfirming: mintHook.isConfirming,
      isSuccess: mintHook.isSuccess,
      error: mintHook.error,
    },
    burnState: {
      hash: burnHook.hash,
      isPending: burnHook.isPending,
      isConfirming: burnHook.isConfirming,
      isSuccess: burnHook.isSuccess,
      error: burnHook.error,
    },
    snapshotState: {
      hash: snapshotHook.hash,
      isPending: snapshotHook.isPending,
      isConfirming: snapshotHook.isConfirming,
      isSuccess: snapshotHook.isSuccess,
      error: snapshotHook.error,
    },
    transferState: {
      hash: transferHook.hash,
      isPending: transferHook.isPending,
      isConfirming: transferHook.isConfirming,
      isSuccess: transferHook.isSuccess,
      error: transferHook.error,
    },
    approveState: {
      hash: approveHook.hash,
      isPending: approveHook.isPending,
      isConfirming: approveHook.isConfirming,
      isSuccess: approveHook.isSuccess,
      error: approveHook.error,
    },
    
    // Refresh functions
    refetch: () => {
      refetchInfo()
      refetchBalance()
    },
  }
}
