data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv_project6" {
  name                = "kv-project6-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/26"]
}

resource "azurerm_subnet" "privatelink_subnet" {
  name                 = "privatelink-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_dev" {
  name                = "bastion-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tunneling_enabled   = true

  ip_configuration {
    name                 = "bastion_ip_config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}


resource "azurerm_monitor_private_link_scope" "ampls_project4" {
  name                  = "ampls-project4"
  resource_group_name   = azurerm_resource_group.rg.name
  ingestion_access_mode = "PrivateOnly"
}

resource "azurerm_monitor_private_link_scoped_service" "law_connection" {
  name                = "law-connection-scoped"
  resource_group_name = azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls_project4.name
  linked_resource_id  = azurerm_log_analytics_workspace.law_project4.id
}

resource "azurerm_private_dns_zone" "privatelink_oms" {
  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "privatelink_ods" {
  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "oms_vnet_link" {
  name                  = "link-to-vnet-dev"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_oms.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "ods_vnet_link" {
  name                  = "link-to-vnet-dev"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_ods.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "pe_law_project4" {
  name                = "pe-law-project4"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.privatelink_subnet.id

  private_service_connection {
    name                           = "law-connection"
    private_connection_resource_id = azurerm_monitor_private_link_scope.ampls_project4.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default-zone-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.privatelink_oms.id,
      azurerm_private_dns_zone.privatelink_ods.id,
    ]
  }
}


resource "azurerm_log_analytics_workspace" "law_project4" {
  name                = "law-project4-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}