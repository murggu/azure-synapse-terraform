variable "location" {
  default = "North Europe"
}

variable "prefix" {
  type    = string
  default = "syn"
}

resource "random_string" "postfix" {
  length  = 6
  special = false
  upper   = false
}

variable "aad_login" {
  description = "AAD login"
  type = object({
    name      = string
    object_id = string
    tenant_id = string
  })
  default = {
    name      = "AzureAD Admin"
    object_id = "00000000-0000-0000-0000-000000000000"
    tenant_id = "00000000-0000-0000-0000-000000000000"
  }
}

variable "jumphost_username" {
  default = "azureuser"
}

variable "jumphost_password" {
  default = "ThisIsNotVerySecure!"
}

variable "synadmin_username" {
  default = "sqladminuser"
}

variable "synadmin_password" {
  default = "ThisIsNotVerySecure!"
}

variable "enable_syn_sqlpool" {
  description = "Variable to enable or disable Synapse Dedicated SQL pool deployment"
  default     = false
}

variable "enable_syn_sparkpool" {
  description = "Variable to enable or disable Synapse Spark pool deployment"
  default     = false
}