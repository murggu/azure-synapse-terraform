# Virtual Network definition

resource "azurerm_virtual_network" "syn_vnet" {
  name                = "${var.prefix}-vnet-${random_string.postfix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
}

resource "azurerm_subnet" "default_subnet" {
  name                 = "${var.prefix}-default-subnet-${random_string.postfix.result}"
  resource_group_name  = azurerm_resource_group.syn_rg.name
  virtual_network_name = azurerm_virtual_network.syn_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.syn_rg.name
  virtual_network_name = azurerm_virtual_network.syn_vnet.name
  address_prefixes     = ["10.0.10.0/27"]
}