module "storage_account" {
  source = "github.com/murggu/azure-terraform-modules/storage-account"

  rg_name  = module.resource_group.name
  location = module.resource_group.location

  prefix  = var.prefix
  postfix = random_string.postfix.result

  vnet_id   = module.virtual_network.id
  subnet_id = azurerm_subnet.default_subnet.id

  hns_enabled                         = true
  firewall_bypass                     = ["None"]
  firewall_virtual_network_subnet_ids = []
  private_dns_zone_ids_blob           = [azurerm_private_dns_zone.sa_zone_blob.id]
  private_dns_zone_ids_dfs            = [azurerm_private_dns_zone.sa_zone_dfs.id]
}

# DNS Zones

resource "azurerm_private_dns_zone" "st_zone_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = module.resource_group.location
}

resource "azurerm_private_dns_zone" "st_zone_dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = module.resource_group.location
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "st_zone_blob_link" {
  name                  = "${var.postfix}_link_blob"
  resource_group_name   = module.resource_group.location
  private_dns_zone_name = azurerm_private_dns_zone.st_zone_blob.name
  virtual_network_id    = module.virtual_network.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "st_zone_dfs_link" {
  name                  = "${var.postfix}_link_dfs"
  resource_group_name   = module.resource_group.location
  private_dns_zone_name = azurerm_private_dns_zone.st_zone_dfs.name
  virtual_network_id    = module.virtual_network.id
}