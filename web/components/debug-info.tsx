'use client'

import { useAccount } from 'wagmi'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { getYeilAddress } from '@/lib/contracts'

export function DebugInfo() {
  const { address, chainId, isConnected } = useAccount()
  const contractAddress = getYeilAddress(chainId)

  return (
    <Card className="border-yellow-500">
      <CardHeader>
        <CardTitle>🐛 Debug Info</CardTitle>
      </CardHeader>
      <CardContent className="space-y-2 font-mono text-xs">
        <div>
          <strong>Connected:</strong> {isConnected ? 'Yes' : 'No'}
        </div>
        <div>
          <strong>Wallet Address:</strong> {address || 'Not connected'}
        </div>
        <div>
          <strong>Chain ID:</strong> {chainId || 'Not detected'}
        </div>
        <div>
          <strong>Contract Address:</strong> {contractAddress || 'Not found for this chain'}
        </div>
        <div>
          <strong>Expected Chain ID:</strong> 31337 (Localhost)
        </div>
        <div>
          <strong>Expected Contract:</strong> 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
        </div>
      </CardContent>
    </Card>
  )
}
