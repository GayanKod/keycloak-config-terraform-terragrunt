terraform {
  source = "/home/gayan/Documents/keycloak-config-with-terragrunt/keycloak-terraform"
}

inputs = {
  server_url = "http://localhost:8080/auth"
  included_scopes = ["scope_two", "scope_three"]
}
