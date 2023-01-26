data "azurerm_key_vault" "sample-keycloak" {
  name                = "sample-keycloak"
  resource_group_name = var.azure_resource_group
}

data "azurerm_key_vault_secret" "keycloak-username" {
  name         = "keycloak-username"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "keycloak-pw" {
  name         = "keycloak-pw"
  key_vault_id = var.key_vault_id
}