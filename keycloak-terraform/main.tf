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


resource "keycloak_role" "role_one" {
	realm_id = keycloak_realm.realm.id
  	name = "role_one"
	count = contains(var.included_scopes, "scope_one") ? 1 : 0
}

resource "keycloak_role" "role_two" {
  	realm_id = keycloak_realm.realm.id
  	name = "role_two"
	count = contains(var.included_scopes, "scope_two") ? 1 : 0
}

resource "keycloak_role" "role_three" {
  	realm_id = keycloak_realm.realm.id
  	name = "role_three"
	count = contains(var.included_scopes, "scope_three") ? 1 : 0
}


resource "keycloak_authentication_flow" "copy-of-browser-flow" {
  realm_id = keycloak_realm.realm.id
  alias    = "Copy of Browser"
}

resource "keycloak_authentication_execution" "browser-copy-cookie" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.copy-of-browser-flow.alias
  authenticator     = "auth-cookie"
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_execution" "browser-copy-kerberos" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.copy-of-browser-flow.alias
  authenticator     = "auth-spnego"
  requirement       = "DISABLED"
}

resource "keycloak_authentication_execution" "browser-copy-idp-redirect" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.copy-of-browser-flow.alias
  authenticator     = "identity-provider-redirector"
  requirement       = "ALTERNATIVE"
  depends_on = [
    keycloak_authentication_execution.browser-copy-cookie
  ]
}

resource "keycloak_authentication_subflow" "browser-copy-flow-forms" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_flow.copy-of-browser-flow.alias
  alias             = "Forms"
  requirement       = "ALTERNATIVE"
  depends_on = [
    keycloak_authentication_execution.browser-copy-idp-redirect
  ]
}

resource "keycloak_authentication_execution" "browser-copy-auth-username-password-form" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.browser-copy-flow-forms.alias
  authenticator     = "auth-username-password-form"
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_subflow" "browser-copy-conditional" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.browser-copy-flow-forms.alias
  alias             = "Browser copy - Conditional OTP"
  requirement       = "CONDITIONAL"
  depends_on = [
    keycloak_authentication_execution.browser-copy-auth-username-password-form
  ]
}

resource "keycloak_authentication_execution" "browser-copy-conditional-user-configured" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.browser-copy-conditional.alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_execution" "browser-copy-otp" {
  realm_id          = keycloak_realm.realm.id
  parent_flow_alias = keycloak_authentication_subflow.browser-copy-conditional.alias
  authenticator     = "auth-otp-form"
  requirement       = "ALTERNATIVE"
  depends_on = [
    keycloak_authentication_execution.browser-copy-conditional-user-configured
  ]
}

resource "keycloak_authentication_execution_config" "config" {
  realm_id     = keycloak_realm.realm.id
  execution_id = keycloak_authentication_execution.browser-copy-idp-redirect.id
  alias        = "idp-XXX-config"
  config = {
    defaultProvider = "idp-XXX"
  }
}

