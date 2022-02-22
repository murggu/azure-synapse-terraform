# Spark pool

module "synapse_spark_pool" {
  source = "github.com/murggu/azure-terraform-modules/synapse-pools"

  postfix              = random_string.postfix.result
  synapse_workspace_id = module.synapse_workspace.id

  enable_syn_sparkpool = var.enable_syn_sparkpool
}

# Dedicated SQL pool

module "synapse_dedicated_sql_pool" {
  source = "github.com/murggu/azure-terraform-modules/synapse-pools"

  postfix              = random_string.postfix.result
  synapse_workspace_id = module.synapse_workspace.id

  enable_syn_sqlpool = var.enable_syn_sqlpool
}