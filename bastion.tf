resource "azurerm_bastion_host" "syn_bas" {
  name                = "bas-${local.basename}"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.syn_snet_bastion.id
    public_ip_address_id = azurerm_public_ip.syn_pip.id
  }
}

resource "azurerm_public_ip" "syn_pip" {
  name                = "pip-${local.basename}"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}