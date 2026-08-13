# __generated__ by Terraform from "/subscriptions/B5B6FDDA-4BA6-4831-9AAA-4C63754F2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Insights/actionGroups/ag-project4-email"
resource "azurerm_monitor_action_group" "ag_project4" {
  enabled             = true
  location            = "eastus"
  name                = "ag-project4-email"
  resource_group_name = "rg-project3-tf-dev"
  short_name          = "Project4"
  tags                = {}
  email_receiver {
    email_address           = "sariahsworld6@gmail.com"
    name                    = "email-me_-EmailAction-"
    use_common_alert_schema = false
  }
}

# __generated__ by Terraform from "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Automation/automationAccounts/aa-project5-dev"
resource "azurerm_automation_account" "aa_project5" {
  local_authentication_enabled  = true
  location                      = "eastus"
  name                          = "aa-project5-dev"
  public_network_access_enabled = true
  resource_group_name           = "rg-project3-tf-dev"
  sku_name                      = "Basic"
  tags                          = {}
  identity {
    identity_ids = []
    type         = "SystemAssigned"
  }
}

# __generated__ by Terraform
resource "azurerm_automation_runbook" "start_dev_vms" {
  automation_account_name = "aa-project5-dev"
  content                 = "Connect-AzAccount -Identity\n\n$resourceGroup = \"rg-project3-tf-dev\"\n$vms = Get-AzVM -ResourceGroupName $resourceGroup\n\nforeach ($vm in $vms) {\n    Write-Output \"Starting $($vm.Name)...\"\n    Start-AzVM -ResourceGroupName $resourceGroup -Name $vm.Name -NoWait\n}\n\nWrite-Output \"Start commands issued for $($vms.Count) VM(s) in $resourceGroup.\""
  description             = null
  location                 = "eastus"
  log_activity_trace_level = 0
  log_progress             = false
  log_verbose              = false
  name                     = "Start-DevVMs"
  resource_group_name      = "rg-project3-tf-dev"
  runbook_type             = "PowerShell"
  tags                     = {}
}

# __generated__ by Terraform
resource "azurerm_automation_runbook" "stop_dev_vms" {
  automation_account_name = "aa-project5-dev"
  content                 = "Connect-AzAccount -Identity\n\n$resourceGroup = \"rg-project3-tf-dev\"\n$vms = Get-AzVM -ResourceGroupName $resourceGroup\n\nforeach ($vm in $vms) {\n    Write-Output \"Stopping $($vm.Name)...\"\n    Stop-AzVM -ResourceGroupName $resourceGroup -Name $vm.Name -Force -NoWait\n}\n\nWrite-Output \"Stop commands issued for $($vms.Count) VM(s) in $resourceGroup.\""
  description             = null
  location                 = "eastus"
  log_activity_trace_level = 0
  log_progress             = false
  log_verbose              = false
  name                     = "Stop-DevVMs"
  resource_group_name      = "rg-project3-tf-dev"
  runbook_type             = "PowerShell"
  tags                     = {}
}


resource "azurerm_automation_job_schedule" "start_dev_vms_schedule" {
  resource_group_name    = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa_project5.name
  schedule_name           = "weekday-start"
  runbook_name             = azurerm_automation_runbook.start_dev_vms.name
}

resource "azurerm_automation_job_schedule" "stop_dev_vms_schedule" {
  resource_group_name    = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa_project5.name
  schedule_name           = "weekday-stop"
  runbook_name             = azurerm_automation_runbook.stop_dev_vms.name
}