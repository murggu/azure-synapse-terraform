module "storage_account" {
  source = "github.com/murggu/azure-terraform-modules/storage-account"

  rg_name  = module.resource_group.name
  location = module.resource_group.location

  prefix  = var.prefix
  postfix = random_string.postfix.result

  vnet_id     = module.virtual_network.id
  subnet_id   = azurerm_subnet.default_subnet.id
  hns_enabled = true
}