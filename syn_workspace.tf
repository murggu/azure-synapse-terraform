# Azure Synapse Workspace 

resource "azurerm_synapse_workspace" "syn_ws" {
  name                                 = "${var.prefix}-ws-${random_string.postfix.result}"
  resource_group_name                  = azurerm_resource_group.syn_rg.name
  location                             = azurerm_resource_group.syn_rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.syn_ws_adls.id

  sql_administrator_login              = var.synadmin_username
  sql_administrator_login_password     = var.synadmin_password

  managed_virtual_network_enabled	     = true

  aad_admin {
    login     = var.aad_login.name
    object_id = var.aad_login.object_id
    tenant_id = var.aad_login.tenant_id
  }  
}

# Virtual Network & Firewall configuration

resource "azurerm_synapse_firewall_rule" "allow_my_ip" {
  name                 = "AllowMyPublicIp"
  synapse_workspace_id = azurerm_synapse_workspace.syn_ws.id
  start_ip_address     = data.http.ip.body
  end_ip_address       = data.http.ip.body
} 

# DNS Zones

resource "azurerm_private_dns_zone" "syn_zone_dev" {
  name                = "privatelink.dev.azuresynapse.net"
  resource_group_name = azurerm_resource_group.syn_rg.name
}

resource "azurerm_private_dns_zone" "syn_zone_sql" {
  name                = "privatelink.sql.azuresynapse.net"
  resource_group_name = azurerm_resource_group.syn_rg.name
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "syn_zone_dev_link" {
  name                  = "${random_string.postfix.result}_link_dev"
  resource_group_name   = azurerm_resource_group.syn_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.syn_zone_dev.name
  virtual_network_id    = azurerm_virtual_network.syn_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_sql_link" {
  name                  = "${random_string.postfix.result}_link_sql"
  resource_group_name   = azurerm_resource_group.syn_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.syn_zone_sql.name
  virtual_network_id    = azurerm_virtual_network.syn_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "syn_ws_pe_dev" {
  name                = "${var.prefix}-ws-pe-dev-${random_string.postfix.result}"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  subnet_id           = azurerm_subnet.default_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-syn-ws-psc-dev-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_synapse_workspace.syn_ws.id
    subresource_names              = ["dev"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-dev"
    private_dns_zone_ids = [azurerm_private_dns_zone.syn_zone_dev.id]
  }
}

resource "azurerm_private_endpoint" "syn_ws_pe_sql" {
  name                = "${var.prefix}-ws-pe-sql-${random_string.postfix.result}"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  subnet_id           = azurerm_subnet.default_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-syn-ws-pe-sql-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_synapse_workspace.syn_ws.id
    subresource_names              = ["sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.syn_zone_sql.id]
  }
}

resource "azurerm_private_endpoint" "syn_ws_pe_sqlondemand" {
  name                = "${var.prefix}-ws-pe-sqlondemand-${random_string.postfix.result}"
  location            = azurerm_resource_group.syn_rg.location
  resource_group_name = azurerm_resource_group.syn_rg.name
  subnet_id           = azurerm_subnet.default_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-syn-ws-pe-sqlondemand-${random_string.postfix.result}"
    private_connection_resource_id = azurerm_synapse_workspace.syn_ws.id
    subresource_names              = ["sqlondemand"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-sqlondemand"
    private_dns_zone_ids = [azurerm_private_dns_zone.syn_zone_sql.id]
  }
}

# Managed Private Endpoint configuration

resource "azurerm_synapse_managed_private_endpoint" "syn_ws_pe_managed_sa_dfs" {
  name                 = "${var.prefix}-ws-sa-managed-pe-dfs-${random_string.postfix.result}"
  synapse_workspace_id = azurerm_synapse_workspace.syn_ws.id
  target_resource_id   = azurerm_storage_account.syn_ws_sa.id
  subresource_name     = "dfs"

  depends_on = [azurerm_synapse_firewall_rule.allow_my_ip]
} 

# Once the Synapse Managed Endpoint request has been created, approve it 

resource "null_resource" "azurecli_syn_approve_pe_adf_01" {

  provisioner "local-exec" {

       interpreter = ["/bin/bash", "-c"]
       working_dir = "${path.module}"

      # https://github.com/Azure/azure-cli/issues/13573
      command = <<EOT
          synId=$(az storage account show -n $storageAccountName --query "privateEndpointConnections[2].id" -o tsv | tr -d '\r\n')
          echo "APPROVING |"$synId"|"
          az storage account private-endpoint-connection approve --id $synId --description "Approved by Terraform"
      EOT

      environment = {
        storageAccountName = "${azurerm_storage_account.syn_ws_sa.name}"
        resourceGroup = "${azurerm_resource_group.syn_rg.name}"
      }
  }

  depends_on = [
    time_sleep.wait_50_seconds
  ]
}

resource "null_resource" "azurecli_syn_add_exception_01" {

  provisioner "local-exec" {

      # https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/develop-storage-files-storage-access-control?tabs=user-identity
      command = "az storage account network-rule add --resource-group $resourceGroup --account-name $storageAccountName --tenant-id $tenantId --resource-id $synWorkspaceId"

      environment = {
        storageAccountName = "${azurerm_storage_account.syn_ws_sa.name}"
        resourceGroup = "${azurerm_resource_group.syn_rg.name}"
        tenantId = "${var.aad_login.tenant_id}"
        synWorkspaceId = "${azurerm_synapse_workspace.syn_ws.id}"
      }
  }

  depends_on = [
    time_sleep.wait_50_seconds
  ]
}

resource "time_sleep" "wait_50_seconds" {

  depends_on = [
    azurerm_synapse_managed_private_endpoint.syn_ws_pe_managed_sa_dfs
  ]

  create_duration = "50s"
}