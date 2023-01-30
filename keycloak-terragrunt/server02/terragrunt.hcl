terraform {
  source = "/home/gayan/Documents/keycloak-config-with-terragrunt/keycloak-terraform"
}

inputs = {
  server_url = "http://localhost:8090/auth"
  token_url = "http://localhost:8080/token"
  included_scopes = ["scope_one"]
}