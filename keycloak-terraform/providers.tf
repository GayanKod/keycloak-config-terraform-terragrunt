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



provider "keycloak" {
	client_id 	= var.client_id
	username 	= data.azurerm_key_vault_secret.keycloak-username.value
	password 	= data.azurerm_key_vault_secret.keycloak-pw.value
	url 		= var.server_url
}