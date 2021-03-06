@description('The Projects name will be the first Part of the resource name')
param project string

@description('Resource Location.')
param location string

param appServicePlanSku object = {
  name: 'F1'
  tier: 'Free'
}

@description('Scaling worker size ID.')
param workerSizeId int

@description('Scaling worker count.')
param workerCount int

@description('It is used to make the resource names unique but still predictable')
var resourceGroup_id = uniqueString(resourceGroup().id)

var servicePlanName = '${project}-asp-${resourceGroup_id}'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: servicePlanName
  location: location
  tags: {
    DisplayName: 'App Service Plan'
  }
  sku: appServicePlanSku
  kind: 'linux'
  properties: {
    targetWorkerSizeId: workerSizeId
    targetWorkerCount: workerCount
    reserved: true
  }
}

output appserviceplan_name string = appServicePlan.name
