module "synapse_private_link_hub" {
  source = "github.com/murggu/azure-terraform-modules/synapse-private-link-hub"

  rg_name  = module.resource_group.name
  location = module.resource_group.location

  prefix  = var.prefix
  postfix = random_string.postfix.result

  subnet_id = azurerm_subnet.default_subnet.id
}