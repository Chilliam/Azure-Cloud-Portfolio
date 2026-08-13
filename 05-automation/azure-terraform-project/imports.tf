import {
  to = azurerm_monitor_action_group.ag_project4
  id = "/subscriptions/B5B6FDDA-4BA6-4831-9AAA-4C63754F2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Insights/actionGroups/ag-project4-email"
}

import {
  to = azurerm_monitor_metric_alert.alert_high_cpu_web
  id = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Insights/metricAlerts/alert-high-cpu-web"
}

import {
  to = azurerm_monitor_data_collection_rule.dcr_project4
  id = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Insights/dataCollectionRules/dcr-project4-perfcounters"
}

import {
  to = azurerm_dev_test_global_vm_shutdown_schedule.shutdown_web
  id = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.DevTestLab/schedules/shutdown-computevm-vm-web-dev"
}

import {
  to = azurerm_dev_test_global_vm_shutdown_schedule.shutdown_web2
  id = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.DevTestLab/schedules/shutdown-computevm-vm-web2-dev"
}

import {
  to = azurerm_automation_account.aa_project5
  id = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Automation/automationAccounts/aa-project5-dev"
}

import {
  to = azurerm_automation_runbook.stop_dev_vms
  id = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Automation/automationAccounts/aa-project5-dev/runbooks/Stop-DevVMs"
}

import {
  to = azurerm_automation_runbook.start_dev_vms
  id = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Automation/automationAccounts/aa-project5-dev/runbooks/Start-DevVMs"
}
