# Azure Synapse Terraform Example

This repo shows an example for rolling out a complete Synapse enterprise environment via Terraform.

![Deployed resources](media/arch_syn01.png "Deployed resources")

This includes rollout of the following resources:

- Azure Synapse Workspace with Private Endpoints
- Azure Synapse Private Link Hub with Private Endpoint 
- Azure Storage Account with Private Endpoints for `blob` and `dfs`
- Azure Key Vault with Private Endpoint 
- Virtual Network
- Jumphost (Windows) with Bastion for easy access to the VNet

## Instructions

Make sure you have the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [Terraform](https://www.terraform.io/downloads.html) installed. 

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update `terraform.tfvars` with your desired values
3. Run Terraform
    ```console
    $ terraform init
    $ terraform plan
    $ terraform apply
    ```
    
## Notes
See notes below for additional info:

- A public IP is added to Azure Storage Account and Azure Synapse firewall rules to enable the deployment. That rule could be removed once the deployment is finished, only limiting jumphost access.
- Change `enable_syn_sqlpool` and `enable_syn_sparkpool` values if you wanna deploy any of those pools.
