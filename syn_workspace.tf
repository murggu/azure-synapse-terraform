module "synapse_workspace" {
  source = "github.com/murggu/azure-terraform-modules/synapse-workspace"

  rg_name  = module.resource_group.name
  location = module.resource_group.location

  prefix  = var.prefix
  postfix = random_string.postfix.result

  vnet_id   = module.virtual_network.id
  subnet_id = azurerm_subnet.default_subnet.id

  adls_id              = module.storage_account.adls_id
  storage_account_id   = module.storage_account.id
  storage_account_name = module.storage_account.name
  key_vault_id         = module.key_vault.id
  key_vault_name       = module.key_vault.name

  synadmin_username = var.synadmin_username
  synadmin_password = var.synadmin_password

  aad_login = {
    name      = var.aad_login.name
    object_id = var.aad_login.object_id
    tenant_id = var.aad_login.tenant_id
  }
}