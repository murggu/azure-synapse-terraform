# Synapse pools with feature flags, change variable values to enable those (false by default)

# Sql Pool 

resource "azurerm_synapse_sql_pool" "syn_pool_sql" {
  name                 = "syndp${random_string.postfix.result}"
  synapse_workspace_id = azurerm_synapse_workspace.syn_ws.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  count                = var.enable_syn_sqlpool ? 1 : 0
}

# Spark Pool 

resource "azurerm_synapse_spark_pool" "syn_pool_spark" {
  name                 = "synsp${random_string.postfix.result}"
  synapse_workspace_id = azurerm_synapse_workspace.syn_ws.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  count                = var.enable_syn_sparkpool ? 1 : 0

  auto_scale {
    max_node_count = 50
    min_node_count = 3
  }

  auto_pause {
    delay_in_minutes = 15
  }
}