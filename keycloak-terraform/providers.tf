terraform{
	required_providers{
		keycloak = {
			source = "mrparkers/keycloak"
			version = ">= 4.1.0"
		}

		azurerm = {
      		source = "hashicorp/azurerm"
      		version = "3.39.1"
    	}
	}
}

provider "azurerm" {
  features {
  }
}

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

provider "keycloak" {
	client_id 	= var.client_id
	username 	= data.azurerm_key_vault_secret.keycloak-username.value
	password 	= data.azurerm_key_vault_secret.keycloak-pw.value
	url 		= var.server_url
}