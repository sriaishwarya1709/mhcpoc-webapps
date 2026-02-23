#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Configures Azure App Registrations with GitHub OIDC federated credentials
.DESCRIPTION
    Creates App Registrations for GitHub Actions to authenticate to Azure using OIDC
.PARAMETER ResourceGroupName
    Name of the Azure resource group
.PARAMETER GitHubOrg
    GitHub organization or username
.PARAMETER GitHubRepo
    GitHub repository name
.PARAMETER GitHubBranch
    GitHub branch name (default: main)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepo,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubBranch = "main"
)

$ErrorActionPreference = "Stop"

Write-Host "🔐 Configuring GitHub OIDC authentication for Azure..." -ForegroundColor Cyan

# Get subscription details
$subscription = az account show | ConvertFrom-Json
$subscriptionId = $subscription.id
$tenantId = $subscription.tenantId

Write-Host "✓ Subscription: $($subscription.name)" -ForegroundColor Green
Write-Host "✓ Tenant ID: $tenantId" -ForegroundColor Green

# Get resource group resources
$resources = az resource list --resource-group $ResourceGroupName | ConvertFrom-Json
$apiApp = $resources | Where-Object { $_.type -eq 'Microsoft.Web/sites' -and $_.name -like '*api*' } | Select-Object -First 1
$uiApp = $resources | Where-Object { $_.type -eq 'Microsoft.Web/sites' -and $_.name -like '*webui*' } | Select-Object -First 1

if (-not $apiApp -or -not $uiApp) {
    Write-Error "Could not find API or UI web apps in resource group $ResourceGroupName"
    exit 1
}

Write-Host "`nFound web apps:"
Write-Host "  API: $($apiApp.name)"
Write-Host "  UI:  $($uiApp.name)"

# Function to create app registration with federated credential
function New-AppRegistrationWithFederated {
    param(
        [string]$DisplayName,
        [string]$WebAppName,
        [string]$Subject
    )
    
    Write-Host "`nCreating App Registration: $DisplayName..." -ForegroundColor Yellow
    
    # Create app registration
    $appReg = az ad app create --display-name $DisplayName --output json | ConvertFrom-Json
    $appId = $appReg.appId
    
    Write-Host "✓ App Registration created: $appId" -ForegroundColor Green
    
    # Create service principal
    $sp = az ad sp create --id $appId --output json | ConvertFrom-Json
    $spObjectId = $sp.id
    
    Write-Host "✓ Service Principal created: $spObjectId" -ForegroundColor Green
    
    # Add federated credential
    $credentialParams = @{
        name = "github-$GitHubRepo-$GitHubBranch"
        issuer = "https://token.actions.githubusercontent.com"
        subject = $Subject
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Compress
    
    az ad app federated-credential create `
        --id $appId `
        --parameters $credentialParams `
        --output none
    
    Write-Host "✓ Federated credential configured" -ForegroundColor Green
    
    # Assign Contributor role to the web app
    Write-Host "Assigning Website Contributor role to $WebAppName..." -ForegroundColor Yellow
    
    # Get web app resource ID
    $webAppId = (az webapp show --name $WebAppName --resource-group $ResourceGroupName --query id -o tsv)
    
    # Wait a bit for service principal to propagate
    Start-Sleep -Seconds 10
    
    # Assign role
    az role assignment create `
        --assignee $spObjectId `
        --role "Website Contributor" `
        --scope $webAppId `
        --output none
    
    Write-Host "✓ Role assigned" -ForegroundColor Green
    
    return @{
        ClientId = $appId
        ObjectId = $spObjectId
        Name = $DisplayName
    }
}

# Create app registrations for both apps
$apiSubject = "repo:$GitHubOrg/${GitHubRepo}:ref:refs/heads/$GitHubBranch"
$apiAppReg = New-AppRegistrationWithFederated `
    -DisplayName "GitHub-$GitHubRepo-API-Deploy" `
    -WebAppName $apiApp.name `
    -Subject $apiSubject

$uiAppReg = New-AppRegistrationWithFederated `
    -DisplayName "GitHub-$GitHubRepo-UI-Deploy" `
    -WebAppName $uiApp.name `
    -Subject $apiSubject

# Generate unique secret suffixes (similar to your workflow)
$apiSuffix = ([guid]::NewGuid().ToString() -replace '-', '').ToUpper().Substring(0, 32)
$uiSuffix = ([guid]::NewGuid().ToString() -replace '-', '').ToUpper().Substring(0, 32)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔑 GITHUB SECRETS - Add these to your repository" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nFor MoviesApi ($($apiApp.name)):"
Write-Host "AZUREAPPSERVICE_CLIENTID_${apiSuffix}: $($apiAppReg.ClientId)"
Write-Host "AZUREAPPSERVICE_TENANTID_${apiSuffix}: $tenantId"
Write-Host "AZUREAPPSERVICE_SUBSCRIPTIONID_${apiSuffix}: $subscriptionId"

Write-Host "`nFor MoviesUi ($($uiApp.name)):"
Write-Host "AZUREAPPSERVICE_CLIENTID_${uiSuffix}: $($uiAppReg.ClientId)"
Write-Host "AZUREAPPSERVICE_TENANTID_${uiSuffix}: $tenantId"
Write-Host "AZUREAPPSERVICE_SUBSCRIPTIONID_${uiSuffix}: $subscriptionId"
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "⚠️  IMPORTANT:" -ForegroundColor Yellow
Write-Host "1. Add the secrets above to your GitHub repository"
Write-Host "2. Update your workflow files to use these new secret names"
Write-Host "3. Update workflows with correct app names:"
Write-Host "   - API app name: $($apiApp.name)"
Write-Host "   - UI app name: $($uiApp.name)"
Write-Host "`n✅ OIDC configuration complete!" -ForegroundColor Green
