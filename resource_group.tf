resource "azurerm_resource_group" "syn_rg" {
  name     = var.resource_group
  location = var.location
}