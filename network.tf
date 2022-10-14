# Virtual Network

resource "azurerm_virtual_network" "syn_vnet" {
  name                = "vnet-${local.basename}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
}

# Subnets

resource "azurerm_subnet" "syn_snet_default" {
  name                                           = "snet-${local.basename}"
  resource_group_name                            = azurerm_resource_group.syn_rg.name
  virtual_network_name                           = azurerm_virtual_network.syn_vnet.name
  address_prefixes                               = ["10.0.1.0/24"]
  service_endpoints                              = []
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "syn_snet_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.syn_rg.name
  virtual_network_name = azurerm_virtual_network.syn_vnet.name
  address_prefixes     = ["10.0.10.0/27"]
}