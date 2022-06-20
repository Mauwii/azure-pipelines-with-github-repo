# Connect to Azure-CLI as Service Principal
az login `
  --service-principal `
  -u $env:ApplicationId `
  -p $env:ClientSecret `
  -t $env:TenantId

# Get Subscriptions
$AzSubscriptions = Get-AzSubscription

$currentUTCtime = (Get-Date).ToUniversalTime()

foreach ($AzSubscription in $AzSubscriptions) {
  Write-Host `
    -ForegroundColor Cyan `
    -NoNewline `
    "Subscription:"
  Write-Host $AzSubscription.Name `n

  Set-AzContext `
    -Subscription $AzSubscription.Id

  az account set --subscription $AzSubscription.Id

  $AzResourceGroups = Get-AzResourceGroup

  foreach ($AzResourceGroup in $AzResourceGroups) {
    $AzResources = Get-AzResource `
      -ResourceGroupName $AzResourceGroup.ResourceGroupName
    Write-Host `
      -ForegroundColor Cyan `
      -NoNewline `
      "Resource Group: "
    Write-Host $AzResourceGroup.ResourceGroupName

    foreach ($AzResource in $AzResources) {
      az resource list `
        --location $AzResource.Location `
        --name $AzResource.Name `
        --query "[].{Name:name, RG:resourceGroup, Created:createdTime, Changed:changedTime}" `
        -o json |
      ConvertFrom-Json

    }
    Write-Host `
      -ForegroundColor Cyan `
      -NoNewline `
      "Done with ResourceGroup "
    Write-Host $AzResourceGroup.ResourceGroupName `n
  }
  Write-Host `
    -ForegroundColor Cyan `
    -NoNewline `
    "Done with Subscription "
  Write-Host $AzSubscription.Name `n
}
# Create Credential
$User = $env:ApplicationId
$PWord = ConvertTo-SecureString -String $env:ClientSecret -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

# Connect to Azure Powershell as Service Principal
Connect-AzAccount `
  -ServicePrincipal `
  -Credential $Credential `
  -TenantId $env:TenantId

# Connect to Azure-CLI as Service Principal
az login `
  --service-principal `
  -u $env:ApplicationId `
  -p $env:ClientSecret `
  -t $env:TenantId

# Get Subscriptions
$AzSubscriptions = Get-AzSubscription

$currentUTCtime = (Get-Date).ToUniversalTime()

foreach ($AzSubscription in $AzSubscriptions) {
  Write-Host `
    -ForegroundColor Cyan `
    -NoNewline `
    "Subscription:"
  Write-Host $AzSubscription.Name `n

  Set-AzContext `
    -Subscription $AzSubscription.Id

  az account set --subscription $AzSubscription.Id

  $AzResourceGroups = Get-AzResourceGroup

  foreach ($AzResourceGroup in $AzResourceGroups) {
    $AzResources = Get-AzResource `
      -ResourceGroupName $AzResourceGroup.ResourceGroupName
    Write-Host `
      -ForegroundColor Cyan `
      -NoNewline `
      "Resource Group: "
    Write-Host $AzResourceGroup.ResourceGroupName

    foreach ($AzResource in $AzResources) {
      az resource list `
        --location $AzResource.Location `
        --name $AzResource.Name `
        --query "[].{Name:name, RG:resourceGroup, Created:createdTime, Changed:changedTime}" `
        -o json |
      ConvertFrom-Json

    }
    Write-Host `
      -ForegroundColor Cyan `
      -NoNewline `
      "Done with ResourceGroup "
    Write-Host $AzResourceGroup.ResourceGroupName `n
  }
  Write-Host `
    -ForegroundColor Cyan `
    -NoNewline `
    "Done with Subscription "
  Write-Host $AzSubscription.Name `n
}
