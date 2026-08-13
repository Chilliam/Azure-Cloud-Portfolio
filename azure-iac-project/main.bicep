param location string = resourceGroup().location
param environmentName string
param adminUsername string
@secure()
param sshPublicKey string

module network 'modules/network.bicep' = {
  name: 'networkDeploy'
  params: {
    location: location
    vnetName: 'vnet-${environmentName}'
  }
}

module webVm 'modules/vm.bicep' = {
  name: 'webVmDeploy'
  params: {
    location: location
    vmName: 'vm-web-${environmentName}'
    subnetId: network.outputs.webSubnetId
    assignPublicIp: true
    adminUsername: adminUsername
    adminPasswordOrKey: sshPublicKey
  }
}

module dataVm 'modules/vm.bicep' = {
  name: 'dataVmDeploy'
  params: {
    location: location
    vmName: 'vm-data-${environmentName}'
    subnetId: network.outputs.dataSubnetId
    assignPublicIp: false
    adminUsername: adminUsername
    adminPasswordOrKey: sshPublicKey
  }
}


