# Key Vault with Private Endpoint

resource "azurerm_key_vault" "syn_kv" {
  name                = "kv-${local.basename}"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
    bypass                     = "None"
  }
}

# DNS Zones

resource "azurerm_private_dns_zone" "syn_kv_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.syn_rg.name
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "syn_kv_zone_link" {
  name                  = "${random_string.postfix.result}_link_kv"
  resource_group_name   = azurerm_resource_group.syn_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.syn_kv_zone.name
  virtual_network_id    = azurerm_virtual_network.syn_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "syn_kv_pe" {
  name                = "pe-${azurerm_key_vault.syn_kv.name}-vault"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  subnet_id           = azurerm_subnet.syn_snet_default.id

  private_service_connection {
    name                           = "psc-kv-${local.basename}"
    private_connection_resource_id = azurerm_key_vault.syn_kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.syn_kv_zone.id]
  }
}