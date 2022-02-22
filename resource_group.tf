module "resource_group" {
  source = "github.com/murggu/azure-terraform-modules/resource-group"

  location = var.location

  prefix  = var.prefix
  postfix = random_string.postfix.result
}