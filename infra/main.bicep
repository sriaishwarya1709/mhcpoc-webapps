@description('Location for all resources')
param location string = resourceGroup().location

@description('Base name for resources')
param baseName string = 'mhc'

@description('Environment name (e.g., dev, prod)')
param environment string = 'prod'

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${baseName}${environment}'
var acrName = 'acr${resourcePrefix}${uniqueSuffix}'
var apiAppName = 'app-${baseName}-api-${environment}-${uniqueSuffix}'
var uiAppName = 'app-${baseName}-webui-${environment}-${uniqueSuffix}'
var apiAppServicePlanName = 'plan-${baseName}-api-${environment}'
var uiAppServicePlanName = 'plan-${baseName}-ui-${environment}'

// Azure Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

// App Service Plan for API
resource apiAppServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: apiAppServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  kind: 'windows'
  properties: {
    reserved: false
  }
}

// App Service Plan for UI
resource uiAppServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: uiAppServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  kind: 'windows'
  properties: {
    reserved: false
  }
}

// Web App for Movies API
resource apiWebApp 'Microsoft.Web/sites@2023-01-01' = {
  name: apiAppName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: apiAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v10.0'
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'dotnet'
        }
      ]
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
  }
}

// Web App for Movies UI
resource uiWebApp 'Microsoft.Web/sites@2023-01-01' = {
  name: uiAppName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: uiAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v10.0'
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'dotnet'
        }
      ]
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'MoviesApi__BaseUrl'
          value: 'https://${apiWebApp.properties.defaultHostName}'
        }
      ]
    }
  }
}

// Outputs
output acrName string = containerRegistry.name
output acrLoginServer string = containerRegistry.properties.loginServer
output apiWebAppName string = apiWebApp.name
output apiWebAppUrl string = 'https://${apiWebApp.properties.defaultHostName}'
output uiWebAppName string = uiWebApp.name
output uiWebAppUrl string = 'https://${uiWebApp.properties.defaultHostName}'
output resourceGroupName string = resourceGroup().name
output location string = location

// Outputs for GitHub Secrets (you'll need to run additional scripts to get these values)
output acrAdminUsername string = containerRegistry.name
output instructions string = 'Run the post-deployment script to configure GitHub federated credentials and retrieve secrets'
