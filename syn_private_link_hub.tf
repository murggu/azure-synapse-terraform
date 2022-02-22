resource "azurerm_synapse_private_link_hub" "syn_hub" {
  name                = "${var.prefix}plh${random_string.postfix.result}"
  resource_group_name = azurerm_resource_group.syn_rg.name
  location            = azurerm_resource_group.syn_rg.location
} 

# DNS Zones

resource "azurerm_private_dns_zone" "syn_zone_web" {
  name                = "privatelink.azuresynapse.net"
  resource_group_name = azurerm_resource_group.syn_rg.name
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "syn_hub_pe_web" {
  name                = "${var.prefix}-hub-pe-web-${random_string.postfix.result}"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  subnet_id           = azurerm_subnet.default_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-hub-psc-web-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_synapse_private_link_hub.syn_hub.id
    subresource_names              = ["web"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
     name                 = "private-dns-zone-group-syn-web"
    private_dns_zone_ids = [azurerm_private_dns_zone.syn_zone_web.id]
  }
}