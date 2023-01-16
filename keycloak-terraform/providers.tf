terraform{
	required_providers{
		keycloak = {
			source = "mrparkers/keycloak"
			version = ">= 4.1.0"
		}
	}
}

provider "keycloak" {
	client_id 	= var.client_id
	username 	= var.username
	password 	= var.password
	url 		= var.server_url
}