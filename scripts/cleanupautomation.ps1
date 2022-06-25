param(
  [Switch]$LocalTest
)

# Connect to Azure-CLI as Service Principal
[void](
  az login `
    --service-principal `
    -u $env:ApplicationId `
    -p $env:ClientSecret `
    -t $env:SpTenantId
)

# Get Current UTC-Time
$CurrentUTCtime = (Get-Date).ToUniversalTime()

# Set Initial Date
$InitialDate = (Get-Date -Year 2022 -Month 06 -Day 15).ToUniversalTime()

# Days until Resources get deleted
$NewerResourceDays = 7
$OlderResourceDays = 14

# Initialize Variables to count existing and deleted Resources/RGs
$AllAzRgCount = 0
$DeletedAzRgCount = 0
$AllAzResourceCount = 0
$DeletedAzResourceCount = 0

# Function to Print Information
function Write-Info {
  param (
    [System.String]$Title,
    [System.String]$Value,
    [Switch]$InitialNewLine,
    [Switch]$FinalNewLine
  )
  $Title = "${Title}: "
  $Value = "`t${Value}"
  if ($InitialNewLine) {
    $Title = "`n${Title}"
  }
  if ($FinalNewLine) {
    $Value = "${Value}`n"
  }
  Write-Host `
    -ForegroundColor Cyan `
    -NoNewline `
    $Title
  Write-Host $Value
}

# Iterate over subscriptions
foreach ($AzSubscription in Get-AzSubscription) {

  # Set Context to current Subscription
  [void](
    Set-AzContext `
      -Subscription $AzSubscription.Id
  )
  [void](az account set `
      --subscription $AzSubscription.Id
  )
  # Get Resourcegroups of current Context
  $AzResourceGroups = Get-AzResourceGroup

  # Add Number of ResourceGroups to AllAzRg
  $AllAzRgCount += $AzResourceGroups.Length

  # Get Number of Resources in current Context
  $AzResourceCount = (Get-AzResource).Length

  # Add Number of Resources in Subscription to AllAzResourceCount
  $AllAzResourceCount += $AzResourceCount

  # Write Info to Host about current Subscription
  Write-Info `
    -InitialNewLine `
    -Title "Subscription Name" `
    -Value $AzSubscription.Name
  Write-Info `
    -Title "Resourcegroups" `
    -Value $AzResourceGroups.Length
  Write-Info `
    -Title "Resource Count" `
    -Value "$AzResourceCount" `
    -FinalNewLine

  # Iterate over Resource Groups
  foreach ($AzResourceGroup in $AzResourceGroups) {

    # Get Resources in current Resource Group
    $AzResources = Get-AzResource `
      -ResourceGroupName $AzResourceGroup.ResourceGroupName

    # Write Info to Host about Current Resource Group
    Write-Info `
      -Title "Resource Group" `
      -Value $AzResourceGroup.ResourceGroupName
    Write-Info `
      -Title "Resource Count" `
      -Value $AzResources.Length

    # Iterate over Resources in current Resource Group
    foreach ($AzResource in $AzResources) {

      # Get Current Resource Creation Time
      $AzCurrentResource = (
        az resource list `
          --location $AzResource.Location `
          --name $AzResource.Name `
          --query "[].{Name:name, RG:resourceGroup, Created:createdTime, Changed:changedTime}" `
          -o json | ConvertFrom-Json
      )

      # Check if Resource was created before or after initial date to give devs more days to react on older resources
      if (($AzCurrentResource.Created).ToUniversalTime() -gt $InitialDate) {
        $DaysToDelete = $NewerResourceDays - ($CurrentUTCtime - ($AzCurrentResource.Created).ToUniversalTime()).Days
      }
      else {
        $DaysToDelete = $OlderResourceDays - ($CurrentUTCtime - $InitialDate).Days
      }

      # Add/update Tag "DeletionDate" of Resource, or Delete it if defined age has been reached
      if ($DaysToDelete -gt 0) {

        # Write Info to Host when Resource will be deleted
        Write-Host `
          -NoNewline `
          $AzCurrentResource.Name, "will be deleted in $DaysToDelete "
        if ($DaysToDelete -gt 1) {
          Write-Host "Days"
        }
        else {
          Write-Host "Day"
        }

        # Set DeletionDate
        $DeletionDate = $CurrentUTCtime.AddDays($DaysToDelete)

        # Create Tag
        $Tag = @{"DeletionDate" = "$DeletionDate UTC"; }
        [void](
          Update-AzTag `
            -ResourceId $AzResource.Id `
            -Tag $Tag `
            -Operation Merge `
            -WhatIf:$LocalTest
        )
      }
      else {
        # Get Resource Lock
        $AzResourceLock = Get-AzResourceLock `
          -ResourceName $AzResource.Name `
          -ResourceType $AzResource.Type `
          -ResourceGroupName $AzResource.ResourceGroupName

        # Remove Resource Lock if existing
        if ($AzResourceLock) {
          Write-Host "Deleting Resource Lock of $($AzResource.Name)"
          [void](
            Remove-AzResourceLock `
              -LockId $AzResourceLock.LockId `
              -Force:$true `
              -WhatIf:$LocalTest
          )
        }
        # Remove Resource
        $RmResource = Remove-AzResource `
          -ResourceId $AzResource.Id `
          -WhatIf:$LocalTest `
          -ErrorAction:SilentlyContinue `
          -Force:$true

        # Write Info and Increment Deleted Resource Count if succeeded
        if ($RmResource) {
          Write-Host "Deleted $($AzResource.Name)"
          $DeletedAzResourceCount++
        }
        else {
          Write-Host "Could not delete $($AzResource.Name)"
        }
      }
    }

    # Get Resourcecount in current Resource Group
    $AzRgResourceCount = (
      Get-AzResource `
        -ResourceGroupName $AzResourceGroup.ResourceGroupName
    ).Length

    # Delete Resourcegroup if empty
    if ($AzRgResourceCount -eq 0) {
      [void](
        Remove-AzResourceGroup `
          -Name $AzResourceGroup.ResourceGroupName `
          -Force:$true `
          -WhatIf:$LocalTest
      )
      # Write Info to Host that ResourceGroup was deleted
      Write-Info `
        -Title "Deleted Resourcegroup" `
        -Value $AzResourceGroup.ResourceGroupName `
        -FinalNewLine

      # Increment DeletedAzRgCount
      $DeletedAzRgCount++
    }
    else {
      # Write Info to Host that ResourceGroup is done
      Write-Info `
        -Title "Resourcegroup Done" `
        -Value $AzResourceGroup.ResourceGroupName `
        -FinalNewLine
    }
  }

  # Write Info to Host that Subscription is done
  Write-Info `
    -Title "Subscription Done" `
    -Value $AzSubscription.Name `
    -FinalNewLine
}

# Write Info to Host about Resource-Counts
Write-Info `
  -Title "Deleted RGs" `
  -Value "`t$DeletedAzRgCount of $AllAzRgCount"
Write-Info `
  -Title "Deleted resources" `
  -Value "$DeletedAzResourceCount of $AllAzResourceCount"
