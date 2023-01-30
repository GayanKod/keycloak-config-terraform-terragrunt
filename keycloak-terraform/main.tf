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

# Create roles according to the scopes passed to the variable called included_scopes

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

# Create keycloak authentication flow (Copy of Browser Authentication flow)

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


# Create Identify Provider and Config 

resource "keycloak_oidc_identity_provider" "externalID" {
  realm             	= keycloak_realm.realm.id
  alias             	= "externalID"
  display_name 			= "External ID"
  enabled 				= true
  store_token 			= false
  trust_email 			= false
  hide_on_login_page 	= false 
  authorization_url 	= var.token_url
  token_url         	= var.server_url
  logout_url 			= "https://example.com/logout_url"
  backchannel_supported = false
  disable_user_info 	= false
  user_info_url 		= "https://example.com/user_info_url"
  client_id         	= "sample-client-id"
  client_secret     	= "sample-client-secret"
  issuer 				= "https://example.com/issuer"
  default_scopes    	= "openid profile email"
  validate_signature 	= true
  jwks_url 				= "https://example.com/.well-known/jwks.json"
  sync_mode 			= "FORCE"
}


resource "keycloak_attribute_importer_identity_provider_mapper" "email" {
  realm                   = keycloak_realm.realm.id
  name                    = "email"
  claim_name              = "email"
  identity_provider_alias = keycloak_oidc_identity_provider.externalID.alias
  user_attribute          = "email"

  # extra_config with syncMode is required in Keycloak 10+
  extra_config = {
    syncMode = "IMPORT"
  }
}

//hardcoded role identity provider mapper
resource "keycloak_hardcoded_role_identity_provider_mapper" "ad-user-mapper" {
  realm                   = keycloak_realm.realm.id
  name                    = "hardcoded-role-mapper"
  identity_provider_alias = keycloak_oidc_identity_provider.externalID.alias
  role                    = "HARDCODED_ROLE"

  #KC10 support
  extra_config = {
    syncMode = "INHERIT"
  }
}

//user template importer identify provider mapper
resource "keycloak_user_template_importer_identity_provider_mapper" "username" {
  realm                   = keycloak_realm.realm.id
  name                    = "username"
  identity_provider_alias = keycloak_oidc_identity_provider.externalID.alias
  template                = "$${CLAIM.given_name}"

  #KC10 support
  extra_config = {
    syncMode = "LEGACY"
  }
}

//Advanced Group Identity Provider Mappers
resource "keycloak_custom_identity_provider_mapper" "group-mapper-one" {
  realm                    = keycloak_realm.realm.id
  name                     = "group-mapper-one"
  identity_provider_alias  = keycloak_oidc_identity_provider.externalID.alias
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"

  // pulled from dev-tools, tbh.
  extra_config = {
    syncMode = "INHERIT"
    claims = jsonencode([
      { key = "roles", value = "groupone" }
    ])
    "are.claim.values.regex" = "false"
    group = "/GROUP_ONE"
  }
}

resource "keycloak_custom_identity_provider_mapper" "group-mapper-two" {
  realm                    = keycloak_realm.realm.id
  name                     = "group-mapper-two"
  identity_provider_alias  = keycloak_oidc_identity_provider.externalID.alias
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"

  // pulled from dev-tools, tbh.
  extra_config = {
    syncMode = "INHERIT"
    claims = jsonencode([
      { key = "roles", value = "grouptwo" }
    ])
    "are.claim.values.regex" = "false"
    group = "/GROUP_TWO"
  }
}

resource "keycloak_custom_identity_provider_mapper" "group-mapper-three" {
  realm                    = keycloak_realm.realm.id
  name                     = "group-mapper-three"
  identity_provider_alias  = keycloak_oidc_identity_provider.externalID.alias
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"

  // pulled from dev-tools, tbh.
  extra_config = {
    syncMode = "INHERIT"
    claims = jsonencode([
      { key = "roles", value = "groupthree" }
    ])
    "are.claim.values.regex" = "false"
    group = "/GROUP_THREE"
  }
}

resource "keycloak_custom_identity_provider_mapper" "group-mapper-four" {
  realm                    = keycloak_realm.realm.id
  name                     = "group-mapper-four"
  identity_provider_alias  = keycloak_oidc_identity_provider.externalID.alias
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"

  // pulled from dev-tools, tbh.
  extra_config = {
    syncMode = "INHERIT"
    claims = jsonencode([
      { key = "roles", value = "groupfour" }
    ])
    "are.claim.values.regex" = "false"
    group = "/GROUP_FOUR"
  }
}






