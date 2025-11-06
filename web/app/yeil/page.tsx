'use client'

import { useState } from 'react'
import { useAccount } from 'wagmi'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { ConnectWallet } from '@/components/connect-wallet'
import { DebugInfo } from '@/components/debug-info'
import { useYeilContract, useYeilBalanceAt, useYeilTotalSupplyAt } from '@/hooks/use-yeil-contract'
import { 
  Loader2, 
  CheckCircle2, 
  AlertCircle, 
  RefreshCw, 
  Send, 
  Coins,
  ShieldCheck,
  Camera,
  Wallet as WalletIcon
} from 'lucide-react'
import { formatEther } from 'viem'

export default function YeilDashboard() {
  const { address, isConnected } = useAccount()
  console.log('User Address:', address)
  const {
    contractAddress,
    tokenInfo,
    balance,
    isLoading,
    transfer,
    transferState,
    createSnapshot,
    snapshotState,
    refetch,
    mint,
    mintState,
    burn,
    burnState,
  } = useYeilContract()

  console.log('Token Info:', tokenInfo)

  const [transferTo, setTransferTo] = useState('')
  const [transferAmount, setTransferAmount] = useState('')
  const [snapshotId, setSnapshotId] = useState<number>()
  const [mintTo, setMintTo] = useState('')
  const [mintAmount, setMintAmount] = useState('')
  const [burnFrom, setBurnFrom] = useState('')
  const [burnAmount, setBurnAmount] = useState('')
  
  const { balance: balanceAtSnapshot, isLoading: isLoadingSnapshot } = useYeilBalanceAt(address, snapshotId)
  const { totalSupply: totalSupplyAtSnapshot, isLoading: isLoadingTotalSupply } = useYeilTotalSupplyAt(snapshotId)
  const handleTransfer = async () => {
    if (!transferTo || !transferAmount) return
    if (transferState.isPending || transferState.isConfirming) return // Prevent double-click
    
    try {
      await transfer(transferTo as `0x${string}`, transferAmount)
      setTransferTo('')
      setTransferAmount('')
    } catch (err) {
      console.error('Transfer failed:', err)
    }
  }

  const handleMint = async () => {
    if (!mintTo || !mintAmount) return
    if (mintState.isPending || mintState.isConfirming) return // Prevent double-click
    
    try {
      await mint(mintTo as `0x${string}`, mintAmount)
      setMintTo('')
      setMintAmount('')
    } catch (err) {
      console.error('Mint failed:', err)
    }
  }

  const handleSnapshot = async () => {
    if (snapshotState.isPending || snapshotState.isConfirming) return // Prevent double-click
    
    try {
      await createSnapshot()
    } catch (err) {
      console.error('Snapshot failed:', err)
    }
  }

  const handleBurn = async () => {
    if (!burnFrom || !burnAmount) return
    if (burnState.isPending || burnState.isConfirming) return // Prevent double-click
    
    try {
      await burn(burnFrom as `0x${string}`, burnAmount)
      setBurnFrom('')
      setBurnAmount('')
    } catch (err) {
      console.error('Burn failed:', err)
    }
  }

  if (!isConnected) {
    return (
      <div className="min-h-screen bg-background p-8">
        <div className="max-w-4xl mx-auto space-y-8">
          <div className="text-center space-y-4">
            <h1 className="text-4xl font-bold">Yeil Token Dashboard</h1>
            <p className="text-muted-foreground">
              Connect your wallet to interact with Yeil tokens
            </p>
            <ConnectWallet />
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background p-8">
      <div className="max-w-6xl mx-auto space-y-8">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold">Yeil Token Dashboard</h1>
            <p className="text-muted-foreground mt-2">
              Manage your Yeil tokens and view reserve backing
            </p>
          </div>
          <ConnectWallet />
        </div>

        {/* Debug Info */}
        <DebugInfo />

        {/* Token Overview */}
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Your Balance</CardTitle>
              <WalletIcon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <Loader2 className="h-6 w-6 animate-spin" />
              ) : (
                <>
                  <div className="text-2xl font-bold">
                    {balance?.balanceFormatted || '0'} {tokenInfo?.symbol}
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    {balance?.balance ? balance.balance.toString() : '0'} wei
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Supply</CardTitle>
              <Coins className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <Loader2 className="h-6 w-6 animate-spin" />
              ) : (
                <>
                  <div className="text-2xl font-bold">
                    {tokenInfo?.totalSupply ? formatEther(tokenInfo.totalSupply) : '0'}
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    {tokenInfo?.symbol || 'YEIL'} tokens in circulation
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Verified Reserves</CardTitle>
              <ShieldCheck className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <Loader2 className="h-6 w-6 animate-spin" />
              ) : (
                <>
                  <div className="text-2xl font-bold">
                    {tokenInfo?.verifiedReserves ? formatEther(tokenInfo.verifiedReserves) : '0'}
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Backed reserves
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Backing Status</CardTitle>
              <CheckCircle2 className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <Loader2 className="h-6 w-6 animate-spin" />
              ) : (
                <>
                  <Badge variant={tokenInfo?.isFullyBacked ? 'default' : 'destructive'} className="mb-2">
                    {tokenInfo?.isFullyBacked ? 'Fully Backed' : 'Under-collateralized'}
                  </Badge>
                  <p className="text-xs text-muted-foreground">
                    {tokenInfo?.isFullyBacked 
                      ? 'All tokens backed by reserves' 
                      : 'Reserves below total supply'}
                  </p>
                </>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Main Content Tabs */}
        <Tabs defaultValue="transfer" className="w-full">
          <TabsList className="grid w-full grid-cols-5">
            <TabsTrigger value="transfer">Transfer</TabsTrigger>
            <TabsTrigger value="mint">Mint</TabsTrigger>
            <TabsTrigger value="burn">Burn</TabsTrigger>
            <TabsTrigger value="snapshot">Snapshot</TabsTrigger>
            <TabsTrigger value="info">Token Info</TabsTrigger>
          </TabsList>

          {/* Transfer Tab */}
          <TabsContent value="transfer" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Send className="h-5 w-5" />
                  Transfer Tokens
                </CardTitle>
                <CardDescription>
                  Send {tokenInfo?.symbol || 'YEIL'} tokens to another address
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="recipient">Recipient Address</Label>
                  <Input
                    id="recipient"
                    placeholder="0x..."
                    value={transferTo}
                    onChange={(e) => setTransferTo(e.target.value)}
                    disabled={transferState.isPending || transferState.isConfirming}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="amount">Amount</Label>
                  <Input
                    id="amount"
                    type="number"
                    placeholder="0.0"
                    value={transferAmount}
                    onChange={(e) => setTransferAmount(e.target.value)}
                    disabled={transferState.isPending || transferState.isConfirming}
                  />
                  <p className="text-xs text-muted-foreground">
                    Available: {balance?.balanceFormatted || '0'} {tokenInfo?.symbol}
                  </p>
                </div>

                <Button
                  onClick={handleTransfer}
                  disabled={!transferTo || !transferAmount || transferState.isPending || transferState.isConfirming}
                  className="w-full"
                >
                  {transferState.isPending || transferState.isConfirming ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      {transferState.isPending ? 'Confirming...' : 'Processing...'}
                    </>
                  ) : (
                    <>
                      <Send className="mr-2 h-4 w-4" />
                      Transfer Tokens
                    </>
                  )}
                </Button>

                {transferState.hash && (
                  <Alert>
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      Transaction: {transferState.hash.slice(0, 10)}...{transferState.hash.slice(-8)}
                    </AlertDescription>
                  </Alert>
                )}

                {transferState.isSuccess && (
                  <Alert className="border-green-500">
                    <CheckCircle2 className="h-4 w-4 text-green-500" />
                    <AlertDescription className="text-green-500">
                      Transfer successful!
                    </AlertDescription>
                  </Alert>
                )}

                {transferState.error && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      {transferState.error.message}
                    </AlertDescription>
                  </Alert>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* Mint Tab */}
          <TabsContent value="mint" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Coins className="h-5 w-5" />
                  Mint Tokens (Owner Only)
                </CardTitle>
                <CardDescription>
                  Create new {tokenInfo?.symbol || 'YEIL'} tokens and send to an address
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <Alert>
                  <AlertCircle className="h-4 w-4" />
                  <AlertDescription>
                    Only the contract owner can mint new tokens. This operation will fail if you&apos;re not the owner.
                  </AlertDescription>
                </Alert>

                <div className="space-y-2">
                  <Label htmlFor="mintRecipient">Recipient Address</Label>
                  <Input
                    id="mintRecipient"
                    placeholder="0x..."
                    value={mintTo}
                    onChange={(e) => setMintTo(e.target.value)}
                    disabled={mintState.isPending || mintState.isConfirming}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="mintAmount">Amount to Mint</Label>
                  <Input
                    id="mintAmount"
                    type="number"
                    placeholder="0.0"
                    value={mintAmount}
                    onChange={(e) => setMintAmount(e.target.value)}
                    disabled={mintState.isPending || mintState.isConfirming}
                  />
                  <p className="text-xs text-muted-foreground">
                    Current total supply: {tokenInfo?.totalSupply ? formatEther(tokenInfo.totalSupply) : '0'} {tokenInfo?.symbol}
                  </p>
                </div>

                <Button
                  onClick={handleMint}
                  disabled={!mintTo || !mintAmount || mintState.isPending || mintState.isConfirming}
                  className="w-full z-10"
                >
                  {mintState.isPending || mintState.isConfirming ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      {mintState.isPending ? 'Confirming...' : 'Processing...'}
                    </>
                  ) : (
                    <>
                      <Coins className="mr-2 h-4 w-4" />
                      Mint Tokens
                    </>
                  )}
                </Button>

                {mintState.hash && (
                  <Alert>
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      Transaction: {mintState.hash.slice(0, 10)}...{mintState.hash.slice(-8)}
                    </AlertDescription>
                  </Alert>
                )}

                {mintState.isSuccess && (
                  <Alert className="border-green-500">
                    <CheckCircle2 className="h-4 w-4 text-green-500" />
                    <AlertDescription className="text-green-500">
                      Tokens minted successfully!
                    </AlertDescription>
                  </Alert>
                )}

                {mintState.error && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      {mintState.error.message}
                    </AlertDescription>
                  </Alert>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* Burn Tab */}
          <TabsContent value="burn" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <AlertCircle className="h-5 w-5" />
                  Burn Tokens (Owner Only)
                </CardTitle>
                <CardDescription>
                  Destroy {tokenInfo?.symbol || 'YEIL'} tokens from an address
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <Alert>
                  <AlertCircle className="h-4 w-4" />
                  <AlertDescription>
                    Only the contract owner can burn tokens. This permanently removes tokens from circulation.
                  </AlertDescription>
                </Alert>

                <div className="space-y-2">
                  <Label htmlFor="burnFrom">Address to Burn From</Label>
                  <Input
                    id="burnFrom"
                    placeholder="0x..."
                    value={burnFrom}
                    onChange={(e) => setBurnFrom(e.target.value)}
                    disabled={burnState.isPending || burnState.isConfirming}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="burnAmount">Amount to Burn</Label>
                  <Input
                    id="burnAmount"
                    type="number"
                    placeholder="0.0"
                    value={burnAmount}
                    onChange={(e) => setBurnAmount(e.target.value)}
                    disabled={burnState.isPending || burnState.isConfirming}
                  />
                  <p className="text-xs text-muted-foreground">
                    Current total supply: {tokenInfo?.totalSupply ? formatEther(tokenInfo.totalSupply) : '0'} {tokenInfo?.symbol}
                  </p>
                </div>

                <Button
                  onClick={handleBurn}
                  disabled={!burnFrom || !burnAmount || burnState.isPending || burnState.isConfirming}
                  className="w-full"
                  variant="destructive"
                >
                  {burnState.isPending || burnState.isConfirming ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      {burnState.isPending ? 'Confirming...' : 'Processing...'}
                    </>
                  ) : (
                    <>
                      <AlertCircle className="mr-2 h-4 w-4" />
                      Burn Tokens
                    </>
                  )}
                </Button>

                {burnState.hash && (
                  <Alert>
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      Transaction: {burnState.hash.slice(0, 10)}...{burnState.hash.slice(-8)}
                    </AlertDescription>
                  </Alert>
                )}

                {burnState.isSuccess && (
                  <Alert className="border-green-500">
                    <CheckCircle2 className="h-4 w-4 text-green-500" />
                    <AlertDescription className="text-green-500">
                      Tokens burned successfully!
                    </AlertDescription>
                  </Alert>
                )}

                {burnState.error && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      {burnState.error.message}
                    </AlertDescription>
                  </Alert>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* Snapshot Tab */}
          <TabsContent value="snapshot" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Camera className="h-5 w-5" />
                  Snapshot History
                </CardTitle>
                <CardDescription>
                  View balance at specific snapshots
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="snapshotId">Snapshot ID</Label>
                  <Input
                    id="snapshotId"
                    type="number"
                    placeholder="Enter snapshot ID"
                    onChange={(e) => setSnapshotId(e.target.value ? parseInt(e.target.value) : undefined)}
                  />
                </div>

                {snapshotId !== undefined && (
                  <div className="space-y-2 p-4 bg-muted rounded-lg">
                    <div className="flex justify-between">
                      <span className="text-sm text-muted-foreground">Your Balance at Snapshot #{snapshotId}</span>
                      {isLoadingSnapshot ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <span className="text-sm font-medium">
                          {typeof balanceAtSnapshot === 'bigint' ? formatEther(balanceAtSnapshot) : '0'} {tokenInfo?.symbol}
                        </span>
                      )}
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-muted-foreground">Total Supply at Snapshot</span>
                      {isLoadingTotalSupply ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <span className="text-sm font-medium">
                          {typeof totalSupplyAtSnapshot === 'bigint' ? formatEther(totalSupplyAtSnapshot) : '0'} {tokenInfo?.symbol}
                        </span>
                      )}
                    </div>
                  </div>
                )}

                <Separator />

                <div className="space-y-2">
                  <Label>Create New Snapshot (Owner Only)</Label>
                  <Button
                    onClick={handleSnapshot}
                    disabled={snapshotState.isPending || snapshotState.isConfirming}
                    className="w-full"
                    variant="outline"
                  >
                    {snapshotState.isPending || snapshotState.isConfirming ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        Creating Snapshot...
                      </>
                    ) : (
                      <>
                        <Camera className="mr-2 h-4 w-4" />
                        Create Snapshot
                      </>
                    )}
                  </Button>
                </div>

                {snapshotState.isSuccess && (
                  <Alert className="border-green-500">
                    <CheckCircle2 className="h-4 w-4 text-green-500" />
                    <AlertDescription className="text-green-500">
                      Snapshot created successfully!
                    </AlertDescription>
                  </Alert>
                )}

                {snapshotState.error && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      {snapshotState.error.message}
                    </AlertDescription>
                  </Alert>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* Info Tab */}
          <TabsContent value="info" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>Token Information</CardTitle>
                <CardDescription>
                  Detailed information about the Yeil token
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">Contract Address</span>
                    <code className="text-xs font-mono bg-muted px-2 py-1 rounded">
                      {contractAddress || 'Not deployed'}
                    </code>
                  </div>

                  <Separator />

                  <div className="flex justify-between">
                    <span className="text-sm text-muted-foreground">Token Name</span>
                    <span className="text-sm font-medium">{tokenInfo?.name || '-'}</span>
                  </div>

                  <div className="flex justify-between">
                    <span className="text-sm text-muted-foreground">Symbol</span>
                    <span className="text-sm font-medium">{tokenInfo?.symbol || '-'}</span>
                  </div>

                  <div className="flex justify-between">
                    <span className="text-sm text-muted-foreground">Decimals</span>
                    <span className="text-sm font-medium">{tokenInfo?.decimals || '-'}</span>
                  </div>

                  <Separator />

                  <div className="flex justify-between">
                    <span className="text-sm text-muted-foreground">Proof of Reserve Feed</span>
                    <code className="text-xs font-mono bg-muted px-2 py-1 rounded">
                      {tokenInfo?.proofOfReserveFeedAddress ? 
                        `${tokenInfo.proofOfReserveFeedAddress.slice(0, 6)}...${tokenInfo.proofOfReserveFeedAddress.slice(-4)}` 
                        : '-'}
                    </code>
                  </div>
                </div>

                <Button onClick={refetch} variant="outline" className="w-full">
                  <RefreshCw className="mr-2 h-4 w-4" />
                  Refresh Data
                </Button>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>

        {/* Contract Address Note */}
        {contractAddress === '0x0000000000000000000000000000000000000000' && (
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              <strong>Note:</strong> Contract address not configured. Please deploy the Yeil contract 
              and update the address in <code>lib/contracts/addresses.ts</code>
            </AlertDescription>
          </Alert>
        )}
      </div>
    </div>
  )
}
