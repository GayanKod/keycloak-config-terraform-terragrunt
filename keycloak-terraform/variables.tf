variable "key_vault_id" {
  default = "/subscriptions/f32e14d5-8830-47fc-ac4e-8170c7cb845e/resourceGroups/99x/providers/Microsoft.KeyVault/vaults/sample-keycloak"
}

variable "azure_resource_group" {
  default = "99x"
}

variable "key_vault_name" {
  default = "sample-keycloak"  
}

variable "client_id" {
  default = "admin-cli"
}

variable "server_url" {    
  default = "http://localhost:8080/auth"
}