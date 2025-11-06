'use client'

import { useAccount, useBalance, useDisconnect, useEnsName, useSwitchChain } from 'wagmi'
import { useCallback } from 'react'

export function useWallet() {
  const { address, isConnected, chain, chainId } = useAccount()
  const { disconnect } = useDisconnect()
  const { switchChain } = useSwitchChain()
  
  const { data: balance, isLoading: isBalanceLoading, refetch: refetchBalance } = useBalance({
    address: address,
  })
  
  const { data: ensName } = useEnsName({ address })

  const formatAddress = useCallback((addr?: `0x${string}`, short = true) => {
    if (!addr) return ''
    if (short) return `${addr.slice(0, 6)}...${addr.slice(-4)}`
    return addr
  }, [])

  const formatBalance = useCallback((value?: string, decimals = 18, precision = 4) => {
    if (!value) return '0'
    const num = parseFloat(value) / Math.pow(10, decimals)
    return num.toFixed(precision)
  }, [])

  const copyAddressToClipboard = useCallback(async () => {
    if (address) {
      await navigator.clipboard.writeText(address)
      return true
    }
    return false
  }, [address])

  const getExplorerUrl = useCallback((addr?: `0x${string}`) => {
    if (!addr || !chain) return null
    const explorerUrl = chain.blockExplorers?.default.url
    if (!explorerUrl) return null
    return `${explorerUrl}/address/${addr}`
  }, [chain])

  return {
    // Account info
    address,
    isConnected,
    chain,
    chainId,
    ensName,
    
    // Balance info
    balance,
    isBalanceLoading,
    refetchBalance,
    
    // Actions
    disconnect,
    switchChain,
    copyAddressToClipboard,
    
    // Helpers
    formatAddress,
    formatBalance,
    getExplorerUrl,
  }
}
