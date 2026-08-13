# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Insights/dataCollectionRules/dcr-project4-perfcounters"
resource "azurerm_monitor_data_collection_rule" "dcr_project4" {
  data_collection_endpoint_id = null
  description                 = null
  kind                        = null
  location                    = "eastus"
  name                        = "dcr-project4-perfcounters"
  resource_group_name         = "rg-project3-tf-dev"
  tags                        = {}
  data_flow {
    built_in_transform = null
    destinations       = ["la-1559653836"]
    output_stream      = null
    streams            = ["Microsoft-Perf"]
    transform_kql      = null
  }
  data_sources {
    performance_counter {
      counter_specifiers            = ["\\Processor Information(_Total)\\% Processor Time", "\\Processor Information(_Total)\\% Privileged Time", "\\Processor Information(_Total)\\% User Time", "\\Processor Information(_Total)\\Processor Frequency", "\\System\\Processes", "\\Process(_Total)\\Thread Count", "\\Process(_Total)\\Handle Count", "\\System\\System Up Time", "\\System\\Context Switches/sec", "\\System\\Processor Queue Length", "Processor(*)\\% Processor Time", "Processor(*)\\% Idle Time", "Processor(*)\\% User Time", "Processor(*)\\% Nice Time", "Processor(*)\\% Privileged Time", "Processor(*)\\% IO Wait Time", "Processor(*)\\% Interrupt Time", "\\Memory\\% Committed Bytes In Use", "\\Memory\\Available Bytes", "\\Memory\\Committed Bytes", "\\Memory\\Cache Bytes", "\\Memory\\Pool Paged Bytes", "\\Memory\\Pool Nonpaged Bytes", "\\Memory\\Pages/sec", "\\Memory\\Page Faults/sec", "\\Process(_Total)\\Working Set", "\\Process(_Total)\\Working Set - Private", "Memory(*)\\Available MBytes Memory", "Memory(*)\\% Available Memory", "Memory(*)\\Used Memory MBytes", "Memory(*)\\% Used Memory", "Memory(*)\\Pages/sec", "Memory(*)\\Page Reads/sec", "Memory(*)\\Page Writes/sec", "Memory(*)\\Available MBytes Swap", "Memory(*)\\% Available Swap Space", "Memory(*)\\Used MBytes Swap Space", "Memory(*)\\% Used Swap Space", "\\LogicalDisk(_Total)\\% Disk Time", "\\LogicalDisk(_Total)\\% Disk Read Time", "\\LogicalDisk(_Total)\\% Disk Write Time", "\\LogicalDisk(_Total)\\% Idle Time", "\\LogicalDisk(_Total)\\Disk Bytes/sec", "\\LogicalDisk(_Total)\\Disk Read Bytes/sec", "\\LogicalDisk(_Total)\\Disk Write Bytes/sec", "\\LogicalDisk(_Total)\\Disk Transfers/sec", "\\LogicalDisk(_Total)\\Disk Reads/sec", "\\LogicalDisk(_Total)\\Disk Writes/sec", "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer", "\\LogicalDisk(_Total)\\Avg. Disk sec/Read", "\\LogicalDisk(_Total)\\Avg. Disk sec/Write", "\\LogicalDisk(_Total)\\Avg. Disk Queue Length", "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length", "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length", "\\LogicalDisk(_Total)\\% Free Space", "\\LogicalDisk(_Total)\\Free Megabytes", "Logical Disk(*)\\% Free Inodes", "Logical Disk(*)\\% Used Inodes", "Logical Disk(*)\\Free Megabytes", "Logical Disk(*)\\% Free Space", "Logical Disk(*)\\% Used Space", "Logical Disk(*)\\Logical Disk Bytes/sec", "Logical Disk(*)\\Disk Read Bytes/sec", "Logical Disk(*)\\Disk Write Bytes/sec", "Logical Disk(*)\\Disk Transfers/sec", "Logical Disk(*)\\Disk Reads/sec", "Logical Disk(*)\\Disk Writes/sec", "\\Network Interface(*)\\Bytes Total/sec", "\\Network Interface(*)\\Bytes Sent/sec", "\\Network Interface(*)\\Bytes Received/sec", "\\Network Interface(*)\\Packets/sec", "\\Network Interface(*)\\Packets Sent/sec", "\\Network Interface(*)\\Packets Received/sec", "\\Network Interface(*)\\Packets Outbound Errors", "\\Network Interface(*)\\Packets Received Errors", "Network(*)\\Total Bytes Transmitted", "Network(*)\\Total Bytes Received", "Network(*)\\Total Bytes", "Network(*)\\Total Packets Transmitted", "Network(*)\\Total Packets Received", "Network(*)\\Total Rx Errors", "Network(*)\\Total Tx Errors", "Network(*)\\Total Collisions"]
      name                          = "perfCounterDataSource60"
      sampling_frequency_in_seconds = 60
      streams                       = ["Microsoft-Perf"]
    }
  }
  destinations {
    log_analytics {
      name                  = "la-1559653836"
      workspace_resource_id = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.OperationalInsights/workspaces/law-project4-dev"
    }
  }
}

# __generated__ by Terraform
resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_web" {
  daily_recurrence_time = "2300"
  enabled               = true
  location              = "eastus"
  tags                  = {}
  timezone              = "UTC"
  virtual_machine_id    = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Compute/virtualMachines/vm-web-dev"
  notification_settings {
    email           = "sariahsworld6@gmail.com"
    enabled         = true
    time_in_minutes = 30
    webhook_url     = null
  }
}

# __generated__ by Terraform
resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_web2" {
  daily_recurrence_time = "2300"
  enabled               = true
  location              = "eastus"
  tags                  = {}
  timezone              = "UTC"
  virtual_machine_id    = "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Compute/virtualMachines/vm-web2-dev"
  notification_settings {
    email           = "sariahsworld6@gmail.com"
    enabled         = true
    time_in_minutes = 30
    webhook_url     = null
  }
}

# __generated__ by Terraform from "/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/Microsoft.Insights/metricAlerts/alert-high-cpu-web"
resource "azurerm_monitor_metric_alert" "alert_high_cpu_web" {
  auto_mitigate            = true
  description              = null
  enabled                  = true
  frequency                = "PT5M"
  name                     = "alert-high-cpu-web"
  resource_group_name      = "rg-project3-tf-dev"
  scopes                   = ["/subscriptions/b5b6fdda-4ba6-4831-9aaa-4c63754f2653/resourceGroups/rg-project3-tf-dev/providers/microsoft.compute/virtualMachines/vm-web-dev"]
  severity                 = 2
  tags                     = {}
  target_resource_location = "eastus"
  target_resource_type     = "microsoft.compute/virtualMachines"
  window_size              = "PT5M"
  action {
    action_group_id    = "/subscriptions/B5B6FDDA-4BA6-4831-9AAA-4C63754F2653/resourceGroups/rg-project3-tf-dev/providers/microsoft.insights/actionGroups/ag-project4-email"
    webhook_properties = {}
  }
  criteria {
    aggregation            = "Average"
    metric_name            = "Percentage CPU"
    metric_namespace       = "microsoft.compute/virtualMachines"
    operator               = "GreaterThan"
    skip_metric_validation = false
    threshold              = 20
  }
}