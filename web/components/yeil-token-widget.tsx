'use client'

import { useYeilContract } from '@/hooks/use-yeil-contract'
import { useAccount } from 'wagmi'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ConnectWallet } from '@/components/connect-wallet'
import { formatEther } from 'viem'
import { Loader2, Wallet, Coins, ShieldCheck } from 'lucide-react'

/**
 * Simple Yeil Token Widget
 * 
 * This component demonstrates basic usage of the useYeilContract hook
 * to display token information and user balance
 */
export function YeilTokenWidget() {
  const { isConnected } = useAccount()
  const { tokenInfo, balance, isLoading } = useYeilContract()

  if (!isConnected) {
    return (
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Yeil Token</CardTitle>
          <CardDescription>Connect to view your balance</CardDescription>
        </CardHeader>
        <CardContent>
          <ConnectWallet />
        </CardContent>
      </Card>
    )
  }

  if (isLoading) {
    return (
      <Card className="w-full max-w-md">
        <CardContent className="flex items-center justify-center py-8">
          <Loader2 className="h-8 w-8 animate-spin" />
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="w-full max-w-md">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Wallet className="h-5 w-5" />
          {tokenInfo?.name || 'Yeil Token'}
        </CardTitle>
        <CardDescription>
          {tokenInfo?.symbol || 'YEIL'} • {tokenInfo?.decimals || 18} decimals
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Your Balance */}
        <div className="flex items-center justify-between p-4 bg-muted rounded-lg">
          <div className="flex items-center gap-2">
            <Wallet className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm text-muted-foreground">Your Balance</span>
          </div>
          <span className="text-lg font-bold">
            {balance?.balanceFormatted || '0'} {tokenInfo?.symbol}
          </span>
        </div>

        {/* Total Supply */}
        <div className="flex items-center justify-between p-4 bg-muted rounded-lg">
          <div className="flex items-center gap-2">
            <Coins className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm text-muted-foreground">Total Supply</span>
          </div>
          <span className="text-sm font-medium">
            {tokenInfo?.totalSupply ? formatEther(tokenInfo.totalSupply) : '0'}
          </span>
        </div>

        {/* Backing Status */}
        <div className="flex items-center justify-between p-4 bg-muted rounded-lg">
          <div className="flex items-center gap-2">
            <ShieldCheck className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm text-muted-foreground">Backing Status</span>
          </div>
          <Badge variant={tokenInfo?.isFullyBacked ? 'default' : 'destructive'}>
            {tokenInfo?.isFullyBacked ? 'Fully Backed' : 'Under-collateralized'}
          </Badge>
        </div>

        {/* Reserves */}
        {tokenInfo?.verifiedReserves && (
          <div className="text-xs text-muted-foreground text-center pt-2 border-t">
            Verified Reserves: {formatEther(tokenInfo.verifiedReserves)} {tokenInfo.symbol}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
