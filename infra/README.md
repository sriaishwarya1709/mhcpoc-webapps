# Infrastructure Deployment

This folder contains Infrastructure as Code (IaC) for deploying the Movies application to Azure.

## Prerequisites

- [Azure CLI](https://aka.ms/azure-cli) installed
- Azure subscription with appropriate permissions
- PowerShell 7+ (for running deployment scripts)

## Resources Created

The Bicep template creates the following Azure resources:

- **Resource Group** - Container for all resources
- **Azure Container Registry (ACR)** - For storing Docker images
- **App Service Plans (2)** - One for API, one for UI
- **Web Apps (2)**:
  - `app{basename}api{env}` - Movies API
  - `app{basename}webui{env}` - Movies UI
- **App Registrations (2)** - For GitHub OIDC authentication (created via script)

## Quick Start

### 1. Update Parameters

Edit `main.bicepparam` and update the following:

```bicep
param githubRepository = 'YOUR_GITHUB_USERNAME/YOUR_REPO_NAME'  // e.g., 'microsoft/movies-demo'
```

### 2. Deploy Infrastructure

Run the deployment script:

```powershell
cd infra
./deploy.ps1
```

This will:
- Create a resource group
- Deploy all Azure resources
- Output ACR credentials

### 3. Configure GitHub OIDC Authentication

Run the OIDC configuration script:

```powershell
./configure-oidc.ps1 `
    -ResourceGroupName "rg-mhcpoc-eus2" `
    -GitHubOrg "YOUR_GITHUB_USERNAME" `
    -GitHubRepo "YOUR_REPO_NAME"
```

This will:
- Create App Registrations for API and UI deployments
- Configure federated credentials for GitHub Actions
- Assign necessary permissions
- Output GitHub secrets

### 4. Add Secrets to GitHub

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** and add:

**From deployment script:**
- `ACR_USERNAME`
- `ACR_PASSWORD`

**From OIDC configuration script:**
- `AZUREAPPSERVICE_CLIENTID_[SUFFIX]` (for API)
- `AZUREAPPSERVICE_TENANTID_[SUFFIX]` (for API)
- `AZUREAPPSERVICE_SUBSCRIPTIONID_[SUFFIX]` (for API)
- `AZUREAPPSERVICE_CLIENTID_[SUFFIX]` (for UI)
- `AZUREAPPSERVICE_TENANTID_[SUFFIX]` (for UI)
- `AZUREAPPSERVICE_SUBSCRIPTIONID_[SUFFIX]` (for UI)

### 5. Update GitHub Workflows

Update your workflow files (`.github/workflows/*.yml`) with:
- Correct secret names from step 4
- Correct app names from deployment output
- Correct ACR name from deployment output

## Manual Deployment (Alternative)

If you prefer to use Azure CLI directly:

```powershell
# Login to Azure
az login

# Create resource group
az group create --name rg-mhcpoc-eus2 --location eastus2

# Deploy Bicep template
az deployment group create \
  --resource-group rg-mhcpoc-eus2 \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## Customization

### Change Resource Names

Edit `main.bicepparam`:

```bicep
param baseName = 'myapp'        // Change base name
param environment = 'dev'        // Change environment
param location = 'westus2'       // Change region
```

### Change SKUs

Edit `main.bicep` and modify the SKU properties:

```bicep
sku: {
  name: 'S1'  // Change from B1 to S1 (Standard)
  tier: 'Standard'
}
```

## Outputs

After deployment, the following information is available:

- ACR Name and Login Server
- Web App Names and URLs
- Resource Group Name
- Instructions for next steps

## Cleanup

To delete all resources:

```powershell
az group delete --name rg-mhcpoc-eus2 --yes --no-wait
```

## Troubleshooting

### Issue: "insufficient privileges" when creating app registrations

**Solution:** Ensure your Azure account has permissions to create App Registrations in Entra ID. You may need:
- Application Administrator role
- Cloud Application Administrator role

### Issue: Deployment fails with "name already exists"

**Solution:** Resource names must be globally unique. Change the `baseName` parameter in `main.bicepparam`.

### Issue: Role assignment fails

**Solution:** Wait a few more seconds for service principal propagation, then retry the OIDC configuration script.

## Architecture

```
┌─────────────────┐
│  GitHub Actions │
└────────┬────────┘
         │ (OIDC Auth)
         ▼
┌─────────────────────────────────┐
│     Azure Subscription          │
│                                 │
│  ┌───────────────────────────┐ │
│  │   Resource Group          │ │
│  │                           │ │
│  │  ┌─────────────────────┐ │ │
│  │  │ Container Registry  │ │ │
│  │  └─────────────────────┘ │ │
│  │                           │ │
│  │  ┌─────────────────────┐ │ │
│  │  │  App Service Plan   │ │ │
│  │  │   ┌──────────────┐  │ │ │
│  │  │   │  Movies API  │  │ │ │
│  │  │   └──────────────┘  │ │ │
│  │  └─────────────────────┘ │ │
│  │                           │ │
│  │  ┌─────────────────────┐ │ │
│  │  │  App Service Plan   │ │ │
│  │  │   ┌──────────────┐  │ │ │
│  │  │   │  Movies UI   │  │ │ │
│  │  │   └──────────────┘  │ │ │
│  │  └─────────────────────┘ │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

## Support

For issues or questions, please open an issue in the repository.
