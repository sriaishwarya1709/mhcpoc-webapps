#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys the Movies application infrastructure to Azure
.DESCRIPTION
    This script deploys all required Azure resources for the Movies application
.PARAMETER ResourceGroupName
    Name of the Azure resource group to create or use
.PARAMETER Location
    Azure region for the resource group
.PARAMETER ParameterFile
    Path to the Bicep parameters file
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-mhcpoc-eus2",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$ParameterFile = "main.bicepparam"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting deployment of Movies application infrastructure..." -ForegroundColor Cyan

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI is not installed. Please install it from https://aka.ms/azure-cli"
    exit 1
}

# Check if logged in to Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in to Azure. Logging in..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "✓ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "✓ Subscription: $($account.name) ($($account.id))" -ForegroundColor Green

# Create resource group if it doesn't exist
Write-Host "`nCreating resource group '$ResourceGroupName' in '$Location'..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location --output none
Write-Host "✓ Resource group ready" -ForegroundColor Green

# Deploy Bicep template
Write-Host "`nDeploying infrastructure..." -ForegroundColor Yellow
$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "main.bicep" `
    --parameters $ParameterFile `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed!"
    exit 1
}

Write-Host "✓ Infrastructure deployed successfully!" -ForegroundColor Green

# Extract outputs
$outputs = $deployment.properties.outputs

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📋 DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Resource Group:     $ResourceGroupName"
Write-Host "Location:           $Location"
Write-Host "ACR Name:           $($outputs.acrName.value)"
Write-Host "ACR Login Server:   $($outputs.acrLoginServer.value)"
Write-Host "API Web App:        $($outputs.apiWebAppName.value)"
Write-Host "API URL:            $($outputs.apiWebAppUrl.value)"
Write-Host "UI Web App:         $($outputs.uiWebAppName.value)"
Write-Host "UI URL:             $($outputs.uiWebAppUrl.value)"
Write-Host "========================================`n" -ForegroundColor Cyan

# Get ACR credentials
Write-Host "Getting ACR credentials..." -ForegroundColor Yellow
$acrName = $outputs.acrName.value
$acrCreds = az acr credential show --name $acrName --output json | ConvertFrom-Json

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔑 GITHUB SECRETS - Add these to your repository" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ACR_USERNAME: $($acrCreds.username)"
Write-Host "ACR_PASSWORD: $($acrCreds.passwords[0].value)"
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "⚠️  NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Run './configure-oidc.ps1' to set up GitHub OIDC authentication"
Write-Host "2. Add the secrets above to your GitHub repository"
Write-Host "3. Update your GitHub workflows with the correct resource names"
Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
