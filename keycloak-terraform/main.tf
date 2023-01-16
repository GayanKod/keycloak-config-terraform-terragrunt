terraform{
	required_providers{
		keycloak = {
			source = "mrparkers/keycloak"
			version = ">= 2.2.0"
		}
	}
}

variable "client_id" {
  default = "admin-cli"
}

variable "username" {
  default = "admin"
}

variable "password" {    
  default = "password"
}

variable "server_url" {    
  default = "http://localhost:8080/auth"
}

provider "keycloak" {
	client_id 	= var.client_id
	username 	= var.username
	password 	= var.password
	url 		= var.server_url
}

resource "keycloak_realm" "realm" {
	realm									= "example-realm"
	display_name							= "Example Realm"
	enabled									= true
	access_code_lifespan 					= "30m"
	sso_session_idle_timeout 				= "30m"
	sso_session_max_lifespan				= "10h"
	offline_session_idle_timeout			= "720h"
	offline_session_max_lifespan_enabled	= false
	registration_allowed					= true
	registration_email_as_username			= true
	reset_password_allowed					= true
	verify_email							= true
	login_with_email_allowed				= true
	account_theme							= "keycloak"
	admin_theme								= "keycloak"
	email_theme								= "keycloak"
	login_theme								= "keycloak"

	internationalization {
		supported_locales = [
			"de",
		]
		default_locale = "de"
	}
	password_policy = "upperCase(1) and length(8) and notUsername(undefined)"

	smtp_server {
		from  	= "your email"
		host	= "your smtp host"
		ssl  	= false 
		starttls  	= false 
		auth {
			username = "your username"
			password = "your password"
		}
	}	
}

resource "keycloak_openid_client" "service" {
	client_id									= "example-client"
	name  										= "Example Client"
	realm_id   									= keycloak_realm.realm.id  
	access_type									= "CONFIDENTIAL"
	access_token_lifespan						= 600
	direct_access_grants_enabled				= false  
	enabled  									= true 
	standard_flow_enabled						= false  
	service_accounts_enabled					= true  
	exclude_session_state_from_auth_response	= false  
}