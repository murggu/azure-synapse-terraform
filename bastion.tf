module "bastion" {
  source = "github.com/murggu/azure-terraform-modules/bastion"

  rg_name  = module.resource_group.name
  location = module.resource_group.location

  prefix  = var.prefix
  postfix = random_string.postfix.result

  subnet_id = azurerm_subnet.bastion_subnet.id
}