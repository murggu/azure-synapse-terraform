# Storage Account with Private Endpoints for blob and dfs

resource "azurerm_storage_account" "syn_st" {
  name                     = "st${local.safe_basename}"
  resource_group_name      = azurerm_resource_group.syn_rg.name
  location                 = azurerm_resource_group.syn_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_role_assignment" "syn_st_role_admin_sbdc" {
  scope                = azurerm_storage_account.syn_st.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "syn_st_role_si_sbdc" {
  scope                = azurerm_storage_account.syn_st.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.syn_ws.identity[0].principal_id
}

resource "azurerm_role_assignment" "syn_st_role_si_c" {
  scope                = azurerm_storage_account.syn_st.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_synapse_workspace.syn_ws.identity[0].principal_id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "syn_ws_adls" {
  name               = "landing"
  storage_account_id = azurerm_storage_account.syn_st.id

  depends_on = [
    azurerm_role_assignment.syn_st_role_admin_sbdc
  ]
}

# Virtual Network & Firewall configuration

resource "azurerm_storage_account_network_rules" "syn_st_firewall_rules" {
  storage_account_id = azurerm_storage_account.syn_st.id

  default_action             = "Deny"
  ip_rules                   = [data.http.ip.body]
  virtual_network_subnet_ids = []
  bypass                     = ["None"]

  # Set network policies after Workspace has been created 
  # depends_on = [azurerm_synapse_workspace.syn_ws]
}

# DNS Zones

resource "azurerm_private_dns_zone" "syn_st_zone_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.syn_rg.name
}

resource "azurerm_private_dns_zone" "syn_st_zone_dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.syn_rg.name
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "syn_st_zone_blob_link" {
  name                  = "${random_string.postfix.result}_link_blob"
  resource_group_name   = azurerm_resource_group.syn_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.syn_st_zone_blob.name
  virtual_network_id    = azurerm_virtual_network.syn_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "syn_st_zone_dfs_link" {
  name                  = "${random_string.postfix.result}_link_dfs"
  resource_group_name   = azurerm_resource_group.syn_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.syn_st_zone_dfs.name
  virtual_network_id    = azurerm_virtual_network.syn_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "syn_st_pe_blob" {
  name                = "pe-${azurerm_storage_account.syn_st.name}-blob"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  subnet_id           = azurerm_subnet.syn_snet_default.id

  private_service_connection {
    name                           = "psc-blob-${local.basename}"
    private_connection_resource_id = azurerm_storage_account.syn_st.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.syn_st_zone_blob.id]
  }
}

resource "azurerm_private_endpoint" "syn_st_pe_dfs" {
  name                = "pe-${azurerm_storage_account.syn_st.name}-dfs"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  subnet_id           = azurerm_subnet.syn_snet_default.id

  private_service_connection {
    name                           = "psc-dfs-${local.basename}"
    private_connection_resource_id = azurerm_storage_account.syn_st.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-dfs"
    private_dns_zone_ids = [azurerm_private_dns_zone.syn_st_zone_dfs.id]
  }
}