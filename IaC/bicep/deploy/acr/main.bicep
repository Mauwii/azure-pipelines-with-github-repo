@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr'

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
@allowed([
  'Basic'
  'Classic'
  'Premium'
  'Standard'
])
param acrSku string = 'Basic'

@description('Enable delete lock')
param enableDeleteLock bool = false

var lockName = '${acrResource.name}-lck'

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: '${acrName}-${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
  }
}

resource lock 'Microsoft.Authorization/locks@2020-05-01' = if (enableDeleteLock) {
  scope: acrResource
  name: lockName
  properties: {
    level: 'CanNotDelete'
  }
}
@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer
