resource "azurerm_resource_group" "syn_rg" {
  name     = "rg-${local.basename}"
  location = var.location
}