# Bootstrap Guide: Setting Up GitHub Actions for Infrastructure Deployment

This guide helps you set up GitHub Actions to deploy your infrastructure using OIDC authentication.

## The Challenge

There's a "chicken and egg" problem:
- ✅ GitHub Actions needs OIDC credentials to deploy infrastructure
- ❌ But OIDC credentials are typically created BY the infrastructure deployment

## Solution: Bootstrap Process

### Step 1: Create Bootstrap App Registration (One-Time Setup)

This App Registration will be used ONLY for infrastructure deployments.

```powershell
# Login to Azure
az login

# Get your subscription and tenant IDs
$subscription = az account show | ConvertFrom-Json
$subscriptionId = $subscription.id
$tenantId = $subscription.tenantId

echo "Subscription ID: $subscriptionId"
echo "Tenant ID: $tenantId"

# Create app registration for infrastructure deployment
$appReg = az ad app create --display-name "GitHub-InfrastructureDeployment" | ConvertFrom-Json
$appId = $appReg.appId

echo "App (Client) ID: $appId"

# Create service principal
$sp = az ad sp create --id $appId | ConvertFrom-Json
$spObjectId = $sp.id

# Add federated credential for GitHub Actions
# REPLACE: YourGitHubOrg/YourRepo with your actual values
$githubRepo = "YourGitHubOrg/YourRepo"  # e.g., "microsoft/movies-demo"
$branch = "main"

$fedParams = @{
    name = "github-infra-deploy"
    issuer = "https://token.actions.githubusercontent.com"
    subject = "repo:${githubRepo}:ref:refs/heads/${branch}"
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json

az ad app federated-credential create --id $appId --parameters $fedParams

echo "✓ Federated credential created"

# Assign Contributor role at subscription level (for creating resource groups)
az role assignment create `
    --assignee $spObjectId `
    --role "Contributor" `
    --scope "/subscriptions/$subscriptionId"

echo "✓ Role assigned"

# Also assign User Access Administrator to grant permissions to created resources
az role assignment create `
    --assignee $spObjectId `
    --role "User Access Administrator" `
    --scope "/subscriptions/$subscriptionId"

echo "✓ User Access Administrator role assigned"
```

### Step 2: Add Bootstrap Secrets to GitHub

Add these three secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```
AZURE_INFRA_CLIENT_ID: <appId from above>
AZURE_TENANT_ID: <tenantId from above>
AZURE_SUBSCRIPTION_ID: <subscriptionId from above>
```

### Step 3: Push and Deploy

```powershell
git add .
git commit -m "Add infrastructure deployment workflow"
git push
```

Then go to GitHub → Actions → "Deploy Azure Infrastructure" → "Run workflow"

### Step 5: Set Up App Deployment Credentials

After infrastructure is created, configure OIDC for app deployments:

```powershell
cd infra
./configure-oidc.ps1 `
    -ResourceGroupName "rg-mhcpoc-eus2" `
    -GitHubOrg "YourGitHubOrg" `
    -GitHubRepo "YourRepo"
```

This creates App Registrations for API and UI deployments and gives you the secrets to add to GitHub.

### Step 6: Update Application Workflows

Update `.github/workflows/main_appmhcapieus2.yml` and `main_appmhcwebuieus2.yml` with:
- Secret names from step 5
- App names from the infrastructure deployment output

## Architecture

```
GitHub Actions Workflow
  ↓ (OIDC Auth)
Bootstrap App Registration
  ↓ (Creates)
Azure Resources (ACR, Web Apps, etc.)
  ↓ (Then configure)
App-Specific App Registrations
  ↓ (Used by)
Application Deployment Workflows
```

## Alternative: Manual Infrastructure Deployment

If you prefer to keep infrastructure deployment manual:

```powershell
cd infra
./deploy.ps1
./configure-oidc.ps1 -ResourceGroupName "rg-mhcpoc-eus2" -GitHubOrg "YourOrg" -GitHubRepo "YourRepo"
```

Then just use GitHub Actions for application deployments.

## Security Best Practices

1. ✅ Use OIDC (no passwords/keys in GitHub)
2. ✅ Separate permissions: Bootstrap app has subscription-level access, app deployment has resource-level access
3. ✅ Limit federated credential to specific branch
4. ✅ Review role assignments regularly

## Troubleshooting

### "Insufficient privileges" error
- Ensure you have Application Administrator role in Entra ID
- Or ask your Azure AD admin to run the bootstrap script

### "Role assignment failed"
- Wait 30-60 seconds after creating service principal
- Service principal propagation takes time

### "Template deployment failed"
- Verify resource names are globally unique

## Support

For issues, open an issue in the repository or check the main README.
