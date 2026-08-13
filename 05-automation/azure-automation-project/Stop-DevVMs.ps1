Connect-AzAccount -Identity

$resourceGroup = "rg-project3-tf-dev"
$vms = Get-AzVM -ResourceGroupName $resourceGroup

foreach ($vm in $vms) {
    Write-Output "Stopping $($vm.Name)..."
    Stop-AzVM -ResourceGroupName $resourceGroup -Name $vm.Name -Force -NoWait
}

Write-Output "Stop commands issued for $($vms.Count) VM(s) in $resourceGroup."