Connect-AzAccount -Identity

$resourceGroup = "rg-project3-tf-dev"
$vms = Get-AzVM -ResourceGroupName $resourceGroup

foreach ($vm in $vms) {
    Write-Output "Starting $($vm.Name)..."
    Start-AzVM -ResourceGroupName $resourceGroup -Name $vm.Name -NoWait
}

Write-Output "Start commands issued for $($vms.Count) VM(s) in $resourceGroup."