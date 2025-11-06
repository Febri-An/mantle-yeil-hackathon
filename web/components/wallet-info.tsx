'use client'

import { useAccount, useBalance, useEnsName } from 'wagmi'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Wallet, Network, Coins } from 'lucide-react'

export function WalletInfo() {
  const { address, isConnected, chain } = useAccount()
  const { data: balance, isLoading: balanceLoading } = useBalance({
    address: address,
  })
  const { data: ensName } = useEnsName({ address })

  if (!isConnected) {
    return (
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Wallet className="h-5 w-5" />
            Wallet Information
          </CardTitle>
          <CardDescription>
            Connect your wallet to view details
          </CardDescription>
        </CardHeader>
      </Card>
    )
  }

  const formatBalance = (value: string, decimals: number) => {
    const num = parseFloat(value) / Math.pow(10, decimals)
    return num.toFixed(4)
  }

  return (
    <Card className="w-full max-w-md">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Wallet className="h-5 w-5" />
          Wallet Information
        </CardTitle>
        <CardDescription>
          Your connected wallet details
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Status</span>
            <Badge variant="default" className="bg-green-500">
              Connected
            </Badge>
          </div>
          
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Address</span>
            <span className="text-sm font-mono">
              {address ? `${address.slice(0, 6)}...${address.slice(-4)}` : '-'}
            </span>
          </div>

          {ensName && (
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">ENS Name</span>
              <span className="text-sm font-medium">{ensName}</span>
            </div>
          )}

          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground flex items-center gap-1">
              <Network className="h-3 w-3" />
              Network
            </span>
            <span className="text-sm font-medium">{chain?.name || 'Unknown'}</span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Chain ID</span>
            <span className="text-sm font-mono">{chain?.id || '-'}</span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground flex items-center gap-1">
              <Coins className="h-3 w-3" />
              Balance
            </span>
            {balanceLoading ? (
              <Skeleton className="h-4 w-24" />
            ) : balance ? (
              <span className="text-sm font-medium">
                {formatBalance(balance.value.toString(), balance.decimals)} {balance.symbol}
              </span>
            ) : (
              <span className="text-sm">-</span>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
