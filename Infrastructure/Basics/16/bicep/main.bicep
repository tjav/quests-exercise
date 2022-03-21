@description(' location of the resources')
param location string = resourceGroup().location
param nsgname string = 'nsgtemplate'  
param pipname string = 'templatepip'
param vnetname string = 'templatevnet'
param subnet1name string = 'templatesnet'
param nicname string = 'templatenic'
param vmname string = 'templatevm'
param user string = 'azuser'
// @secure()
// param password string 
param vmsize string = 'Standard_B1ms'
param kvname2 string = 'vmwin10schaap2'
param objectid string = 'd5531584-638c-4f2a-bab6-4e13dcf6a959'
param nsgrules array = [
  {
    name: 'nsgRule'
    properties: {
      description: 'description'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
]

var secret = '${uniqueString(kvname2)}UPP$#'

module keyvault 'kv.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    name: kvname2
    objectid: objectid
  }
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: '${kvname2}/password'
  properties: {   
    value: secret
  }
  dependsOn:[
    keyvault
  ]
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: nsgname
  location: location
  properties: {
    securityRules: nsgrules
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: pipname
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}



resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnet1name
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}
resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: nicname
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${nicname}_ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
      
    ]
  }
}

module winVM './vm.bicep' = {
  name: 'newVM'
  params: {
    location: location 
    networkInterfaceId : networkInterface.id
    password: secret
    user: user
    vmname: vmname
    vmsize: vmsize
  }
}


// resource autoshutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
//   name: 'autoshutdownvm'
//   location: location
//   properties: {
//     status: 'Enabled'
//     taskType: 'ComputeVmShutdownTask'
//     dailyRecurrence: {
//       time: '1900'
//     }
//     timeZoneId: 'UTC'
//     notificationSettings: {
//       status: 'Disabled'
//       timeInMinutes: 30
//       notificationLocale: 'en'
//     }
//     targetResourceId: winVM.outputs.id
//   }
// }

