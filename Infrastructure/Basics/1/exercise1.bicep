param storageAccountName string
param location string = resourceGroup().location


resource stg 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  
}
