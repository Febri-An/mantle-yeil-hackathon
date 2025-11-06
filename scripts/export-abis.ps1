#!/usr/bin/env pwsh
# Export ABIs from compiled contracts to web/lib/contracts

$ErrorActionPreference = "Stop"

Write-Host "Exporting Contract ABIs..." -ForegroundColor Cyan

# Change to contracts directory
$contractsDir = Join-Path (Split-Path $PSScriptRoot -Parent) "contracts"
Set-Location -Path $contractsDir

# Build contracts first
Write-Host "Building contracts..." -ForegroundColor Yellow
forge build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build contracts" -ForegroundColor Red
    exit 1
}

$webContractsDir = Join-Path (Split-Path $PSScriptRoot -Parent) "web" "lib" "contracts"

# Export Yeil ABI
Write-Host "Exporting Yeil ABI..." -ForegroundColor Yellow
$yeilJsonPath = Join-Path $contractsDir "out" "Yeil.sol" "Yeil.json"
$yeilOutputPath = Join-Path $webContractsDir "yeil-abi-generated.json"

if (Test-Path $yeilJsonPath) {
    $yeilJson = Get-Content $yeilJsonPath -Raw | ConvertFrom-Json
    $yeilJson.abi | ConvertTo-Json -Depth 10 -Compress:$false | Out-File -FilePath $yeilOutputPath -Encoding utf8
    Write-Host "Yeil ABI exported to: $yeilOutputPath" -ForegroundColor Green
} else {
    Write-Host "Yeil.json not found at: $yeilJsonPath" -ForegroundColor Red
    exit 1
}

# Export ProofOfReserveFeed ABI
Write-Host "Exporting ProofOfReserveFeed ABI..." -ForegroundColor Yellow
$proofJsonPath = Join-Path $contractsDir "out" "ProofOfReserveFeed.sol" "ProofOfReserveFeed.json"
$proofOutputPath = Join-Path $webContractsDir "proof-of-reserve-abi-generated.json"

if (Test-Path $proofJsonPath) {
    $proofJson = Get-Content $proofJsonPath -Raw | ConvertFrom-Json
    $proofJson.abi | ConvertTo-Json -Depth 10 -Compress:$false | Out-File -FilePath $proofOutputPath -Encoding utf8
    Write-Host "ProofOfReserveFeed ABI exported to: $proofOutputPath" -ForegroundColor Green
} else {
    Write-Host "ProofOfReserveFeed.json not found at: $proofJsonPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All ABIs exported successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: The TypeScript files import these generated JSON files." -ForegroundColor Cyan
