# Storage Account with VNET binding and Private Endpoints for blob and dfs

resource "azurerm_storage_account" "syn_ws_sa" {
  name                     = "${var.prefix}sa${random_string.postfix.result}"
  resource_group_name      = azurerm_resource_group.syn_rg.name
  location                 = azurerm_resource_group.syn_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_role_assignment" "syn_ws_sa_role_admin_sbdc" {
  scope                = azurerm_storage_account.syn_ws_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
} 

resource "azurerm_role_assignment" "syn_ws_sa_role_si_sbdc" {
  scope                = azurerm_storage_account.syn_ws_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.syn_ws.identity[0]["principal_id"]
}

resource "azurerm_role_assignment" "syn_ws_sa_role_si_c" {
  scope                = azurerm_storage_account.syn_ws_sa.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_synapse_workspace.syn_ws.identity[0]["principal_id"]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "syn_ws_adls" {
  name               = "default"
  storage_account_id = azurerm_storage_account.syn_ws_sa.id

  depends_on = [
    azurerm_role_assignment.syn_ws_sa_role_admin_sbdc
  ]
}

# Virtual Network & Firewall configuration

 resource "azurerm_storage_account_network_rules" "firewall_rules" {
  resource_group_name = azurerm_resource_group.syn_rg.name
  storage_account_name = azurerm_storage_account.syn_ws_sa.name

  default_action             = "Deny"
  ip_rules                   = [data.http.ip.body]
  virtual_network_subnet_ids = []
  bypass                     = ["None"] 

  # Set network policies after Workspace has been created 
  # depends_on = [azurerm_synapse_workspace.syn_ws]
} 

# DNS Zones

resource "azurerm_private_dns_zone" "sa_zone_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.syn_rg.name
}

resource "azurerm_private_dns_zone" "sa_zone_dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.syn_rg.name
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_blob_link" {
  name                  = "${random_string.postfix.result}_link_blob"
  resource_group_name   = azurerm_resource_group.syn_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_blob.name
  virtual_network_id    = azurerm_virtual_network.syn_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_dfs_link" {
  name                  = "${random_string.postfix.result}_link_dfs"
  resource_group_name   = azurerm_resource_group.syn_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_dfs.name
  virtual_network_id    = azurerm_virtual_network.syn_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "sa_pe_blob" {
  name                = "${var.prefix}-sa-pe-blob-${random_string.postfix.result}"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  subnet_id           = azurerm_subnet.default_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-sa-psc-blob-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_storage_account.syn_ws_sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_blob.id]
  }
}

resource "azurerm_private_endpoint" "sa_pe_dfs" {
  name                = "${var.prefix}-sa-pe-dfs-${random_string.postfix.result}"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  subnet_id           = azurerm_subnet.default_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-sa-psc-dfs-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_storage_account.syn_ws_sa.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-dfs"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_dfs.id]
  }
}